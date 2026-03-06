public virtual class ReadinessService {
    public static final String SUBJECT_AT_RISK = 'Follow up: At-risk renewal';
    public static final String SUBJECT_REVIEW  = 'Review renewal readiness';

    // DAO instances for testability
    @TestVisible
    private OpportunityDAO opportunityDAO;
    @TestVisible
    private AccountDAO accountDAO;
    @TestVisible
    private OpportunityLineItemDAO opportunityLineItemDAO;
    @TestVisible
    private TaskDAO taskDAO;
    
    // Constructor for testability
    public ReadinessService() {
        this.opportunityDAO = new OpportunityDAO();
        this.accountDAO = new AccountDAO();
        this.opportunityLineItemDAO = new OpportunityLineItemDAO();
        this.taskDAO = new TaskDAO();
    }
    
    // Constructor for test injection
    public ReadinessService(OpportunityDAO oppDAO, AccountDAO accDAO, OpportunityLineItemDAO oliDAO, TaskDAO taskDAO) {
        this.opportunityDAO = oppDAO;
        this.accountDAO = accDAO;
        this.opportunityLineItemDAO = oliDAO;
        this.taskDAO = taskDAO;
    }

    // Entry point: bulk-safe
    public void recalc(Set<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) return;

        // 1) Load opps + accounts
        List<Opportunity> opps = opportunityDAO.getOpportunitiesByIds(oppIds);

        Set<Id> accountIds = new Set<Id>();
        Set<Id> renewalOppIds = new Set<Id>();
        for (Opportunity o : opps) {
            if (o.AccountId != null) accountIds.add(o.AccountId);
            if (o.Type == 'Renewal' && o.IsClosed == false) renewalOppIds.add(o.Id);
        }
        if (renewalOppIds.isEmpty()) return;

        Map<Id, Account> accById = new Map<Id, Account>(accountDAO.getAccountsByIds(accountIds));

        // 2) Load OLIs and group by opp
        Map<Id, List<OpportunityLineItem>> olisByOpp = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem li : opportunityLineItemDAO.getOpportunityLineItemsByOpportunityIds(renewalOppIds)) {
            if (!olisByOpp.containsKey(li.OpportunityId)) olisByOpp.put(li.OpportunityId, new List<OpportunityLineItem>());
            olisByOpp.get(li.OpportunityId).add(li);
        }

        // 3) Existing tasks for idempotency (only for subject we're controlling)
        Map<Id, Task> existingAtRiskTaskByOpp = new Map<Id, Task>();
        for (Task t : taskDAO.getAtRiskTasksByOpportunityIds(renewalOppIds)) {
            // If duplicates already exist from past sins, keep first; we will delete extras.
            if (!existingAtRiskTaskByOpp.containsKey((Id)t.WhatId)) {
                existingAtRiskTaskByOpp.put((Id)t.WhatId, t);
            }
        }

        // Also find duplicates to cleanup (optional but nice)
        Map<Id, List<Task>> extraAtRiskTasks = new Map<Id, List<Task>>();
        for (Task t : taskDAO.getAtRiskTasksByOpportunityIds(renewalOppIds)) {
            Id oid = (Id)t.WhatId;
            if (existingAtRiskTaskByOpp.containsKey(oid) && existingAtRiskTaskByOpp.get(oid).Id != t.Id) {
                if (!extraAtRiskTasks.containsKey(oid)) extraAtRiskTasks.put(oid, new List<Task>());
                extraAtRiskTasks.get(oid).add(t);
            }
        }

        List<Opportunity> oppUpdates = new List<Opportunity>();
        List<Task> taskUpserts = new List<Task>();
        List<Task> taskDeletes = new List<Task>();
        Set<Id> touchedAccounts = new Set<Id>();

        // 4) Compute per opp
        for (Opportunity o : opps) {
            if (!(o.Type == 'Renewal' && o.IsClosed == false)) continue;

            Account a = accById.get(o.AccountId);
            String priority = (a == null) ? null : a.CustomerPriority__c;
            List<OpportunityLineItem> olis = olisByOpp.containsKey(o.Id) ? olisByOpp.get(o.Id) : new List<OpportunityLineItem>();

            ReadinessCalculator.Result r = ReadinessCalculator.calculate(priority, o.CloseDate, olis);

            o.RenewalHealthScore__c = r.score;
            o.RenewalReadinessStatus__c = r.status;
            o.LastReadinessCalc__c = System.now();
            oppUpdates.add(o);

            if (o.AccountId != null) touchedAccounts.add(o.AccountId);

            // Task contract: At-risk task exists iff Red
            Task existing = existingAtRiskTaskByOpp.get(o.Id);

            if (r.status == 'Red') {
                if (existing != null) {
                    existing.Priority = 'High';
                    if (String.isBlank(existing.Status)) existing.Status = 'Not Started';
                    taskUpserts.add(existing);
                } else {
                    taskUpserts.add(new Task(
                        Subject = SUBJECT_AT_RISK,
                        WhatId = o.Id,
                        Status = 'Not Started',
                        Priority = 'High'
                    ));
                }
            } else {
                if (existing != null) taskDeletes.add(existing);
            }

            // delete any duplicates if existed
            if (extraAtRiskTasks.containsKey(o.Id)) taskDeletes.addAll(extraAtRiskTasks.get(o.Id));
        }

        // 5) DML
        if (!oppUpdates.isEmpty()) opportunityDAO.dmlUpdate(oppUpdates);
        if (!taskUpserts.isEmpty()) taskDAO.dmlUpsert(taskUpserts);
        if (!taskDeletes.isEmpty()) taskDAO.dmlDelete(taskDeletes);

        // 6) Account summary update (deterministic string)
        if (!touchedAccounts.isEmpty()) {
            // Get opportunities for account summaries
            opps = opportunityDAO.getOpportunitiesForAccountSummary(touchedAccounts);
            
            // Calculate account summaries
            Map<Id, Integer> total = new Map<Id, Integer>();
            Map<Id, Integer> greens = new Map<Id, Integer>();
            Map<Id, Integer> ambers = new Map<Id, Integer>();
            Map<Id, Integer> reds = new Map<Id, Integer>();

            for (Opportunity o : opps) {
                Id aid = o.AccountId;
                total.put(aid, (total.containsKey(aid) ? total.get(aid) : 0) + 1);

                if (o.RenewalReadinessStatus__c == 'Green') greens.put(aid, (greens.containsKey(aid) ? greens.get(aid) : 0) + 1);
                else if (o.RenewalReadinessStatus__c == 'Amber') ambers.put(aid, (ambers.containsKey(aid) ? ambers.get(aid) : 0) + 1);
                else if (o.RenewalReadinessStatus__c == 'Red') reds.put(aid, (reds.containsKey(aid) ? reds.get(aid) : 0) + 1);
            }

            List<Account> accUpdates = new List<Account>();
            for (Id aid : touchedAccounts) {
                Integer t = total.containsKey(aid) ? total.get(aid) : 0;
                Integer g = greens.containsKey(aid) ? greens.get(aid) : 0;
                Integer a = ambers.containsKey(aid) ? ambers.get(aid) : 0;
                Integer r = reds.containsKey(aid) ? reds.get(aid) : 0;

                accUpdates.add(new Account(
                    Id = aid,
                    RenewalReadinessSummary__c = t + ' renewals: ' + g + ' Green, ' + a + ' Amber, ' + r + ' Red'
                ));
            }
            
            // Update accounts
            if (!accUpdates.isEmpty()) accountDAO.dmlUpdate(accUpdates);
        }
    }

    // Called from Opportunity before insert (rule: review task)
    public void maybeCreateReviewTasksOnInsert(List<Opportunity> newOpps) {
        if (newOpps == null || newOpps.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : newOpps) {
            if (o.Type == 'Renewal' && o.IsClosed == false && o.AccountId != null) accountIds.add(o.AccountId);
        }
        if (accountIds.isEmpty()) return;

        Map<Id, Account> accById = new Map<Id, Account>(accountDAO.getAccountsByIds(accountIds));

        Date cutoff = Date.today().addDays(30);
        List<Task> reviewTasks = new List<Task>();

        for (Opportunity o : newOpps) {
            if (!(o.Type == 'Renewal' && o.IsClosed == false)) continue;
            Account a = accById.get(o.AccountId);
            if (a == null) continue;

            if (a.CustomerPriority__c == 'High' && o.CloseDate != null && o.CloseDate <= cutoff) {
                reviewTasks.add(new Task(
                    Subject = SUBJECT_REVIEW,
                    WhatId = o.Id,
                    Status = 'Not Started',
                    Priority = 'High'
                ));
            }
        }
        if (!reviewTasks.isEmpty()) opportunityLineItemDAO.dmlInsert(reviewTasks);
    }

    
    // DAO classes for database operations
    
    // Provides database access to Opportunity records
    public inherited sharing virtual class OpportunityDAO {
        public virtual List<Opportunity> getOpportunitiesByIds(Set<Id> opportunityIds) {
            return [
                SELECT Id, AccountId, Type, IsClosed, CloseDate, StageName, Amount,
                       RenewalHealthScore__c, RenewalReadinessStatus__c, LastReadinessCalc__c
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];
        }

         public virtual List<Opportunity> getOpportunitiesForAccountSummary(Set<Id> accountIds) {
            // Count only Renewal opps that have been calculated (LastReadinessCalc != null)
            return [
                SELECT Id, AccountId, RenewalReadinessStatus__c, LastReadinessCalc__c, Type, IsClosed
                FROM Opportunity
                WHERE AccountId IN :accountIds
                  AND Type = 'Renewal'
                  AND IsClosed = false
                  AND LastReadinessCalc__c != null
            ];
        }
        
        public virtual void dmlUpdate(List<SObject> records) { update records; }
    }
    
    // Provides database access to Account records
    public inherited sharing virtual class AccountDAO {
        public virtual List<Account> getAccountsByIds(Set<Id> accountIds) {
            return [
                SELECT Id, CustomerPriority__c, RenewalReadinessSummary__c
                FROM Account
                WHERE Id IN :accountIds
            ];
        }
        
        public virtual void dmlUpdate(List<SObject> records) { update records; }
    }
    
    // Provides database access to OpportunityLineItem records
    public inherited sharing virtual class OpportunityLineItemDAO {
        public virtual List<OpportunityLineItem> getOpportunityLineItemsByOpportunityIds(Set<Id> opportunityIds) {
            return [
                SELECT Id, OpportunityId, Confirmed__c, RiskFlag__c, RiskReason__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :opportunityIds
            ];
        }
        
        public virtual void dmlInsert(List<SObject> records) { insert records; }
    }
    
    // Provides database access to Task records
    public inherited sharing virtual class TaskDAO {
        public virtual List<Task> getAtRiskTasksByOpportunityIds(Set<Id> opportunityIds) {
            return [
                SELECT Id, WhatId, Subject, Status, Priority
                FROM Task
                WHERE WhatId IN :opportunityIds
                  AND Subject = :ReadinessService.SUBJECT_AT_RISK
            ];
        }
        
        public virtual List<Task> getDuplicateAtRiskTasksByOpportunityIds(Set<Id> opportunityIds) {
            return [
                SELECT Id, WhatId, Subject
                FROM Task
                WHERE WhatId IN :opportunityIds
                  AND Subject = :ReadinessService.SUBJECT_AT_RISK
            ];
        }
        
        public virtual void dmlUpsert(List<Task> tasks) { upsert tasks; }
        public virtual void dmlDelete(List<Task> tasks) { delete tasks; }
    }
}
