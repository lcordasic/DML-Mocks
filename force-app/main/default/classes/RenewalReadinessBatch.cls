public class RenewalReadinessBatch implements Database.Batchable<SObject> {
    private Integer staleDays;
    
    // DAO instances for testability
    @TestVisible
    private OpportunityDAO opportunityDAO;
    
    // Constructor for testability
    public RenewalReadinessBatch(Integer staleDays) {
        this.staleDays = (staleDays == null || staleDays <= 0) ? 7 : staleDays;
        this.opportunityDAO = new OpportunityDAO();
    }
    
    // Constructor for test injection
    public RenewalReadinessBatch(Integer staleDays, OpportunityDAO dao) {
        this.staleDays = (staleDays == null || staleDays <= 0) ? 7 : staleDays;
        this.opportunityDAO = dao;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        Date cutoff = System.today().addDays(-staleDays);
        system.debug(getStaleOpportunitiesQuery(cutoff));
        return Database.getQueryLocator(getStaleOpportunitiesQuery(cutoff));
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Set<Id> oppIds = new Set<Id>();
        for (SObject s : scope) oppIds.add((Id)s.get('Id'));
        new ReadinessService().recalc(oppIds);
    }

    public void finish(Database.BatchableContext bc) {}
    
    // Virtual method to allow mocking the query in tests
    public virtual String getStaleOpportunitiesQuery(Date cutoff) {
        return 'SELECT Id FROM Opportunity WHERE Type = \'Renewal\' AND IsClosed = false AND (LastReadinessCalc__c = NULL OR LastReadinessCalc__c < LAST_N_DAYS:7)';
    }
    
    // DAO class for Opportunity operations
    public inherited sharing virtual class OpportunityDAO {
        // Retain extension point for potential non-batch usage
        public virtual List<Opportunity> getStaleOpportunities(Integer staleDays) {
            DateTime cutoff = System.now().addDays(-staleDays);
            return [
                SELECT Id
                FROM Opportunity
                WHERE Type = 'Renewal'
                  AND IsClosed = false
                  AND (LastReadinessCalc__c = NULL OR LastReadinessCalc__c < :cutoff)
            ];
        }
    }
}
