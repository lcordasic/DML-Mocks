public with sharing class OppyLineItemRenewalReadinessHandler {
    
    // DAO instances for testability
    @TestVisible
    private OpportunityLineItemDAO opportunityLineItemDAO;
    
    // Constructor for testability
    public OppyLineItemRenewalReadinessHandler() {
        this.opportunityLineItemDAO = new OpportunityLineItemDAO();
    }
    
    // Constructor for test injection
    public OppyLineItemRenewalReadinessHandler(OpportunityLineItemDAO dao) {
        this.opportunityLineItemDAO = dao;
    }
    
    // BEFORE UPDATE: validation
    public static void beforeUpdate(List<OpportunityLineItem> newList) {
        for (OpportunityLineItem li : newList) {
            if (li.RiskFlag__c == true && String.isBlank(li.RiskReason__c)) {
                li.RiskReason__c.addError('Risk Reason must be provided when Risk Flag is true.');
            }
        }
    }

    // AFTER INSERT/UPDATE/DELETE: recalc parents when influencing
    public static void afterInsert(List<OpportunityLineItem> newList) {
        handleAfterChange(newList, null);
    }
    public static void afterUpdate(List<OpportunityLineItem> newList) {
        handleAfterChange(newList, null);
    }
    public static void afterDelete(List<OpportunityLineItem> oldList) {
        handleAfterChange(null, oldList);
    }

    private static void handleAfterChange(List<OpportunityLineItem> newList, List<OpportunityLineItem> oldList) {
        Set<Id> oppIds = new Set<Id>();

        if (newList != null) {
            for (OpportunityLineItem li : newList) {
                if (li.OpportunityId != null && (li.Confirmed__c == true || li.RiskFlag__c == true)) {
                    oppIds.add(li.OpportunityId);
                }
            }
        }
        if (oldList != null) {
            for (OpportunityLineItem li : oldList) {
                if (li.OpportunityId != null && (li.Confirmed__c == true || li.RiskFlag__c == true)) {
                    oppIds.add(li.OpportunityId);
                }
            }
        }

        if (!oppIds.isEmpty()) {
            new ReadinessService().recalc(oppIds);
        }
    }
    
    // DAO class for OpportunityLineItem operations
    public inherited sharing virtual class OpportunityLineItemDAO {
        public virtual List<OpportunityLineItem> getInfluencingOpportunityLineItemsByOpportunityIds(Set<Id> opportunityIds) {
            return [
                SELECT Id, OpportunityId, Confirmed__c, RiskFlag__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :opportunityIds
                  AND (Confirmed__c = true OR RiskFlag__c = true)
            ];
        }
    }
}
