public with sharing class OpportunityRenewalReadinessHandler {
    
    // DAO instances for testability
    @TestVisible
    private OpportunityLineItemDAO opportunityLineItemDAO;
    
    // Constructor for testability
    public OpportunityRenewalReadinessHandler() {
        this.opportunityLineItemDAO = new OpportunityLineItemDAO();
    }
    
    // Constructor for test injection
    public OpportunityRenewalReadinessHandler(OpportunityLineItemDAO dao) {
        this.opportunityLineItemDAO = dao;
    }
    
    public static void beforeInsert(List<Opportunity> newList) {
        // Intentionally no-op; review task and readiness happen after insert.
    }

    // Static wrapper to align with trigger's static invocation
    public static void afterInsert(List<Opportunity> newList) {
        new OpportunityRenewalReadinessHandler().doAfterInsert(newList);
    }

    // Instance delegate retains testability/DI seams
    @TestVisible
    void doAfterInsert(List<Opportunity> newList) {
        ReadinessService svc = new ReadinessService();
        // 1) Review tasks for High-priority & CloseDate within 30 days
        svc.maybeCreateReviewTasksOnInsert(newList);

        // 2) Initialize readiness only when inserted opps already have influencing OLIs
        //    (Confirmed__c = true OR RiskFlag__c = true). Neutral/no-OLI opps should not be calculated yet.
        Set<Id> renewalOppIds = new Set<Id>();
        for (Opportunity o : newList) {
            if (o.Type == 'Renewal' && o.IsClosed == false) {
                renewalOppIds.add(o.Id);
            }
        }
        if (!renewalOppIds.isEmpty()) {
            // Load OLIs for inserted opps
            Map<Id, Boolean> oppHasInfluencingOli = new Map<Id, Boolean>();
            for (OpportunityLineItem oli : opportunityLineItemDAO.getOpportunityLineItemsByOpportunityIds(renewalOppIds)) {
                if (oli.OpportunityId == null) continue;
                Boolean influences = (oli.Confirmed__c == true || oli.RiskFlag__c == true);
                if (influences) oppHasInfluencingOli.put(oli.OpportunityId, true);
            }
            Set<Id> recalcIds = new Set<Id>();
            for (Id oid : renewalOppIds) {
                if (oppHasInfluencingOli.containsKey(oid) && oppHasInfluencingOli.get(oid) == true) {
                    recalcIds.add(oid);
                }
            }
            if (!recalcIds.isEmpty()) {
                svc.recalc(recalcIds);
            }
        }
    }

    public static void beforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(newList, oldMap);
    }

    public static void afterUpdate() {
        Set<Id> ids = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        if (!ids.isEmpty()) new ReadinessService().recalc(ids);
    }
    
    // DAO class for OpportunityLineItem operations
    public inherited sharing virtual class OpportunityLineItemDAO {
        public virtual List<OpportunityLineItem> getOpportunityLineItemsByOpportunityIds(Set<Id> opportunityIds) {
            return [
                SELECT OpportunityId, Confirmed__c, RiskFlag__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :opportunityIds
            ];
        }
    }
}
