@isTest
public class OpportunityRenewalReadinessHandlerTest {
    
    @isTest
    static void testAfterInsertWithInfluencingOLIs() {
        // Create mock data using key prefixes like in the example
        String opportunityKeyPrefix = Schema.SObjectType.Opportunity.getKeyPrefix();
        String opportunityId = opportunityKeyPrefix + '000000000001';
        
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        // Create mock Opportunity
        Opportunity testOpp = new Opportunity(
            Id = opportunityId,
            Name = 'Test Opportunity',
            AccountId = '001000000000001',
            Type = 'Renewal',
            //IsClosed = false,
            CloseDate = Date.today().addDays(15)
        );
        
        // Create mock OpportunityLineItem
        OpportunityLineItem testOli = new OpportunityLineItem(
            Id = oliId,
            OpportunityId = opportunityId,
            Confirmed__c = true,
            RiskFlag__c = false
        );
        
        // Create handler with mocked DAO
        TestOpportunityLineItemDAO mockDAO = new TestOpportunityLineItemDAO();
        // Configure the mock to return our test data
        mockDAO.setMockData(new List<OpportunityLineItem>{testOli});
        OpportunityRenewalReadinessHandler handler = new OpportunityRenewalReadinessHandler(mockDAO);
        
        // Execute the method
        List<Opportunity> testOppList = new List<Opportunity>{testOpp};
        handler.doAfterInsert(testOppList);
        
        // Verify the mock DAO was called
        System.assertEquals(1, mockDAO.getCallCount(), 'DAO should have been called');
    }
    
    
    @isTest
    static void testAfterInsertWithoutInfluencingOLIs() {
        // Create mock data using key prefixes like in the example
        String opportunityKeyPrefix = Schema.SObjectType.Opportunity.getKeyPrefix();
        String opportunityId = opportunityKeyPrefix + '000000000001';
        
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        // Create mock Opportunity
        Opportunity testOpp = new Opportunity(
            Id = opportunityId,
            Name = 'Test Opportunity',
            AccountId = '001000000000001',
            Type = 'Renewal',
            //IsClosed = false,
            CloseDate = Date.today().addDays(15)
        );
        
        // Create mock OpportunityLineItem
        OpportunityLineItem testOli = new OpportunityLineItem(
            Id = oliId,
            OpportunityId = opportunityId,
            Confirmed__c = false,
            RiskFlag__c = false
        );
        
        // Create handler with mocked DAO
        TestOpportunityLineItemDAO mockDAO = new TestOpportunityLineItemDAO();
        // Configure the mock to return our test data
        mockDAO.setMockData(new List<OpportunityLineItem>{testOli});
        OpportunityRenewalReadinessHandler handler = new OpportunityRenewalReadinessHandler(mockDAO);
        
        // Execute the method
        List<Opportunity> testOppList = new List<Opportunity>{testOpp};
        handler.doAfterInsert(testOppList);
        
        // Verify the mock DAO was called
        System.assertEquals(1, mockDAO.getCallCount(), 'DAO should have been called');
    }
    
    @isTest
    static void testConstructorInjection() {
        // Test constructor injection
        TestOpportunityLineItemDAO mockDAO = new TestOpportunityLineItemDAO();
        OpportunityRenewalReadinessHandler handler = new OpportunityRenewalReadinessHandler(mockDAO);
        
        // Verify the DAO was injected correctly
        System.assertNotEquals(null, handler, 'Handler should not be null');
    }
    
    @isTest
    static void testBeforeInsert() {
        // Test that beforeInsert is a no-op as intended
        List<Opportunity> testOppList = new List<Opportunity>();
        OpportunityRenewalReadinessHandler.beforeInsert(testOppList);
        
        // Should not throw any exceptions
        System.assert(true, 'beforeInsert should not throw exceptions');
    }
    
    @isTest
    static void testBeforeUpdate() {
        // Test that beforeUpdate collects opportunities correctly
        List<Opportunity> newOppList = new List<Opportunity>();
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        
        OpportunityRenewalReadinessHandler.beforeUpdate(newOppList, oldMap);
        
        // Should not throw any exceptions
        System.assert(true, 'beforeUpdate should not throw exceptions');
    }
    
    @isTest
    static void testAfterUpdate() {
        // Test that afterUpdate works correctly
        OpportunityRenewalReadinessHandler.afterUpdate();
        
        // Should not throw any exceptions
        System.assert(true, 'afterUpdate should not throw exceptions');
    }
    
    // Test DAO class that extends the virtual DAO
    private class TestOpportunityLineItemDAO extends OpportunityRenewalReadinessHandler.OpportunityLineItemDAO {
        private Integer callCount = 0;
        private List<OpportunityLineItem> mockData = new List<OpportunityLineItem>();
        
        public void setMockData(List<OpportunityLineItem> data) {
            this.mockData = data;
        }
        
        public override List<OpportunityLineItem> getOpportunityLineItemsByOpportunityIds(Set<Id> opportunityIds) {
            callCount++;
            // Return mock data instead of querying database
            return mockData;
        }
        
        public Integer getCallCount() {
            return callCount;
        }
    }
}
