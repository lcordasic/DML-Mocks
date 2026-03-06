@isTest
public class ReadinessCalculatorTest {
    
    @isTest
    static void testCalculateWithNoOLIs() {
        // Test calculation with no opportunity line items
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        
        ReadinessCalculator.Result result = ReadinessCalculator.calculate('Medium', Date.today().addDays(30), olis);
        
        // Should return a default score of 50 + 5 (Medium priority) = 55 (no confirmed or risk items)
        System.assertEquals(55, result.score, 'Score should be 55 with no OLIs');
        System.assertEquals('Amber', result.status, 'Status should be Amber with score 55');
    }
    
    @isTest
    static void testCalculateWithConfirmedItems() {
        // Test calculation with confirmed items
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        OpportunityLineItem oli = new OpportunityLineItem(
            Id = oliId,
            Confirmed__c = true,
            RiskFlag__c = false,
            RiskReason__c = null
        );
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{oli};
        
        ReadinessCalculator.Result result = ReadinessCalculator.calculate('Medium', Date.today().addDays(30), olis);
        
        // Should get 50 + 5 (Medium priority) + 10 (1 confirmed item) = 65
        System.assertEquals(65, result.score, 'Score should be 65 with 1 confirmed item');
        System.assertEquals('Amber', result.status, 'Status should be Amber with score 65');
    }
    
    @isTest
    static void testCalculateWithRiskItems() {
        // Test calculation with risk items
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        OpportunityLineItem oli = new OpportunityLineItem(
            Id = oliId,
            Confirmed__c = false,
            RiskFlag__c = true,
            RiskReason__c = 'Test risk reason'
        );
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{oli};
        
        ReadinessCalculator.Result result = ReadinessCalculator.calculate('Medium', Date.today().addDays(30), olis);
        
        // Should get 50 + 5 (Medium priority) - 15 (1 risk item) = 40
        System.assertEquals(40, result.score, 'Score should be 40 with 1 risk item');
        System.assertEquals('Red', result.status, 'Status should be Red with score 40');
    }
    
    @isTest
    static void testCalculateWithRiskItemsAndBlankReason() {
        // Test calculation with risk items but blank reason
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        OpportunityLineItem oli = new OpportunityLineItem(
            Id = oliId,
            Confirmed__c = false,
            RiskFlag__c = true,
            RiskReason__c = null  // Blank risk reason
        );
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{oli};
        
        ReadinessCalculator.Result result = ReadinessCalculator.calculate('Medium', Date.today().addDays(30), olis);
        
        // Should get 50 + 5 (Medium priority) - 15 (1 risk item) - 10 (blank reason) = 30
        System.assertEquals(30, result.score, 'Score should be 30 with 1 risk item and blank reason');
        System.assertEquals('Red', result.status, 'Status should be Red with score 30');
    }
    
    @isTest
    static void testCalculateWithHighPriority() {
        // Test calculation with high priority
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        OpportunityLineItem oli = new OpportunityLineItem(
            Id = oliId,
            Confirmed__c = false,
            RiskFlag__c = false,
            RiskReason__c = null
        );
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{oli};
        
        ReadinessCalculator.Result result = ReadinessCalculator.calculate('High', Date.today().addDays(30), olis);
        
        // Should get 50 + 10 (high priority) = 60
        System.assertEquals(60, result.score, 'Score should be 60 with high priority');
        System.assertEquals('Amber', result.status, 'Status should be Amber with score 60');
    }
    
    @isTest
    static void testCalculateWithUrgentDeal() {
        // Test calculation with urgent deal (close date within 14 days)
        String oliKeyPrefix = Schema.SObjectType.OpportunityLineItem.getKeyPrefix();
        String oliId = oliKeyPrefix + '000000000001';
        
        OpportunityLineItem oli = new OpportunityLineItem(
            Id = oliId,
            Confirmed__c = false,
            RiskFlag__c = false,
            RiskReason__c = null
        );
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{oli};
        
        // Close date within 14 days (urgent)
        Date urgentCloseDate = Date.today().addDays(10);
        
        ReadinessCalculator.Result result = ReadinessCalculator.calculate('Medium', urgentCloseDate, olis);
        
        // Should get 50 + 5 (Medium priority) - 10 (urgent deal) = 45
        System.assertEquals(45, result.score, 'Score should be 45 with urgent deal');
        System.assertEquals('Red', result.status, 'Status should be Red with score 45');
    }
    
    
    
    @isTest
    static void testCalculateWithNullValues() {
        // Test with null parameters
        ReadinessCalculator.Result result = ReadinessCalculator.calculate(null, null, null);
        
        // Should return default score of 50
        System.assertEquals(50, result.score, 'Score should be 50 with null parameters');
        System.assertEquals('Amber', result.status, 'Status should be Amber with score 50');
    }
}
