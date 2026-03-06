public with sharing class RenewalReadinessController {
    
    // DAO instances for testability
    @TestVisible
    private static OpportunityDAO opportunityDAO = new OpportunityDAO();
    
    @TestVisible
    private static OpportunityLineItemDAO opportunityLineItemDAO = new OpportunityLineItemDAO();

    // Constructor injection helpers for tests (optional, keep static for Aura/LWC calls)
    @TestVisible
    static void setDAOsForTest(OpportunityDAO oppDao, OpportunityLineItemDAO oliDao) {
        opportunityDAO = (oppDao == null) ? new OpportunityDAO() : oppDao;
        opportunityLineItemDAO = (oliDao == null) ? new OpportunityLineItemDAO() : oliDao;
    }
    
    public class LineItemRow {
        @AuraEnabled public Id id;
        @AuraEnabled public Boolean confirmed;
        @AuraEnabled public Boolean riskFlag;
        @AuraEnabled public String riskReason;
        public LineItemRow() {}
        public LineItemRow(OpportunityLineItem oli) {
            id = oli.Id;
            confirmed = oli.Confirmed__c;
            riskFlag = oli.RiskFlag__c;
            riskReason = oli.RiskReason__c;
        }
    }

    public class ReadinessDTO {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Integer score;
        @AuraEnabled public String status;
        @AuraEnabled public List<LineItemRow> lineItems = new List<LineItemRow>();
    }

    @AuraEnabled(cacheable=true)
    public static ReadinessDTO load(Id opportunityId) {
        Opportunity opp = opportunityDAO.getOpportunityById(opportunityId);

        List<OpportunityLineItem> olis = opportunityLineItemDAO.getOpportunityLineItemsByOpportunityId(opportunityId);

        ReadinessDTO dto = new ReadinessDTO();
        dto.opportunityId = opp.Id;
        dto.score = (opp.RenewalHealthScore__c == null) ? null : Integer.valueOf(opp.RenewalHealthScore__c);
        dto.status = opp.RenewalReadinessStatus__c;

        for (OpportunityLineItem oli : olis) dto.lineItems.add(new LineItemRow(oli));
        return dto;
    }

    @AuraEnabled
    public static ReadinessDTO save(Id opportunityId, List<LineItemRow> changes) {
        // Minimal save: apply changes to OLIs and let triggers/service handle recalculation.
        if (changes == null || changes.isEmpty()) return load(opportunityId);

        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        for (LineItemRow row : changes) {
            if (row == null || row.id == null) continue;
            toUpdate.add(new OpportunityLineItem(
                Id = row.id,
                Confirmed__c = row.confirmed,
                RiskFlag__c = row.riskFlag,
                RiskReason__c = row.riskReason
            ));
        }
        // Delegate DML to DAO using Database methods in USER_MODE
        opportunityLineItemDAO.dmlUpdate(toUpdate);

        return load(opportunityId);
    }
    
    // DAO class for Opportunity operations
    public inherited sharing virtual class OpportunityDAO {
        public virtual Opportunity getOpportunityById(Id opportunityId) {
            return [
                SELECT Id, RenewalHealthScore__c, RenewalReadinessStatus__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
        }
    }
    
    // DAO class for OpportunityLineItem operations
    public inherited sharing virtual class OpportunityLineItemDAO {
        public virtual List<OpportunityLineItem> getOpportunityLineItemsByOpportunityId(Id opportunityId) {
            return [
                SELECT Id, Confirmed__c, RiskFlag__c, RiskReason__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
                ORDER BY CreatedDate
            ];
        }

        // DML operation abstracted for controller
        public virtual void dmlUpdate(List<OpportunityLineItem> items) {
            if (items == null || items.isEmpty()) return;
            // Perform DML using Database methods in USER_MODE per org rules
            Database.update(items, false, AccessLevel.USER_MODE);
        }
    }
}
