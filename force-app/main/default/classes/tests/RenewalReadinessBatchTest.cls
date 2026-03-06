@isTest
public class RenewalReadinessBatchTest {
    
    @isTest
    static void testConstructorWithStaleDays() {
        // Test constructor with stale days parameter
        Integer staleDays = 10;
        RenewalReadinessBatch batch = new RenewalReadinessBatch(staleDays);
        
        // Verify DAO is initialized
        System.assertNotEquals(null, batch.opportunityDAO);
    }
    
    @isTest
    static void testConstructorWithStaleDaysAndDAO() {
        // Test constructor with stale days and DAO injection
        Integer staleDays = 15;
        RenewalReadinessBatch.OpportunityDAO mockDAO = new MockOpportunityDAO();
        RenewalReadinessBatch batch = new RenewalReadinessBatch(staleDays, mockDAO);
        
        // Verify DAO is injected
        System.assertEquals(mockDAO, batch.opportunityDAO);
    }
    
    @isTest
    static void testStartMethod() {
        // Test start method with mock DAO
        MockOpportunityDAO mockDAO = new MockOpportunityDAO();
        RenewalReadinessBatch batch = new RenewalReadinessBatch(7, mockDAO);
        
        // Mock the getStaleOpportunities method to return test data
        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        // Verify that the query locator was returned
        System.assertNotEquals(null, ql);
    }
    
    @isTest
    static void testExecuteMethod() {
        // Create test opportunities using TestDataReader
        List<Opportunity> testOpps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            Opportunity opp = TestDataReader.createTestOpportunity(
                TestDataReader.createGenericOpportunityId(),
                'Test Opportunity ' + i,
                TestDataReader.createGenericAccountId(),
                'Renewal',
                Date.today(),
                10000
            );
            testOpps.add(opp);
        }
        
        // Test execute method with mock DAO
        MockOpportunityDAO mockDAO = new MockOpportunityDAO();
        RenewalReadinessBatch batch = new RenewalReadinessBatch(7, mockDAO);
        
        Test.startTest();
        batch.execute(null, testOpps);
        Test.stopTest();
        
        // Verify that the recalc method was called via ReadinessService
        // This would require checking the mock behavior
    }
    
    @isTest
    static void testFinishMethod() {
        // Test finish method - should do nothing
        RenewalReadinessBatch batch = new RenewalReadinessBatch(7);
        
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        
        // Should not throw any exceptions
    }
    
    @isTest
    static void testGetStaleOpportunitiesQuery() {
        // Test the virtual method that returns the query string
        RenewalReadinessBatch batch = new RenewalReadinessBatch(7);
        
        // Test that the method returns a valid query string
        Date cutoff = System.today().addDays(-7);
        String query = batch.getStaleOpportunitiesQuery(cutoff);
        
        // Verify that the query contains expected components
        System.assert(query.contains('SELECT Id FROM Opportunity'), 'Query should contain SELECT Id FROM Opportunity');
        System.assert(query.contains('Type = \'Renewal\''), 'Query should filter by Type = \'Renewal\'');
        System.assert(query.contains('IsClosed = false'), 'Query should filter by IsClosed = false');
        System.assert(query.contains('LastReadinessCalc__c'), 'Query should include LastReadinessCalc__c filter');
    }
    
    // Mock DAO class for testing
    private class MockOpportunityDAO extends RenewalReadinessBatch.OpportunityDAO {
        public override List<Opportunity> getStaleOpportunities(Integer staleDays) {
            // Return test opportunities for execute method testing
            List<Opportunity> testOpps = new List<Opportunity>();
            for (Integer i = 0; i < 3; i++) {
                Opportunity opp = TestDataReader.createTestOpportunity(
                    TestDataReader.createGenericOpportunityId(),
                    'Test Opportunity ' + i,
                    TestDataReader.createGenericAccountId(),
                    'Renewal',
                    Date.today(),
                    10000
                );
                testOpps.add(opp);
            }
            return testOpps;
        }
    }
    
}
