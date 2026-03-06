@isTest
public class TestDataReader {
    
    // Constants for key prefixes to improve code organization
    private static final String OPP_KEY_PREFIX = Schema.SObjectType.Opportunity.getKeyPrefix();
    private static final String ACC_KEY_PREFIX = Schema.SObjectType.Account.getKeyPrefix();
    
    // Helper method to create test opportunity data
    public static Opportunity createTestOpportunity(String id, String name, String accountId,  String type, Date closeDate, Decimal amount) {
        return new Opportunity(
            Id = id,
            Name = name,
            AccountId = accountId,
            Type = type,
            CloseDate = closeDate,
            Amount = amount
        );
    }
    
    // Helper method to create test opportunity data with default values
    public static Opportunity createTestOpportunity(String name) {
        return new Opportunity(
            Id = '006000000000001',
            Name = name,
            AccountId = '0013H000006Vh9BQAS',
            Type = 'Renewal',
            CloseDate = Date.today().addDays(15),
            Amount = 10000
        );
    }
    
    // Helper method to create test opportunity data with default values and custom type
    public static Opportunity createTestOpportunity(String name, String type) {
        return new Opportunity(
            Id = '006000000000001',
            Name = name,
            AccountId = '0013H000006Vh9BQAS',
            Type = type,
            CloseDate = Date.today().addDays(15),
            Amount = 10000
        );
    }
    
    // Helper method to create test opportunity data with default type and date
    public static Opportunity createTestOpportunity(String id, String accountId, String name, String type) {
        return new Opportunity(
            Id = id,
            Name = name,
            AccountId = accountId,
            Type = type,
            CloseDate = Date.today().addDays(15),
            Amount = 10000
        );
    }
    
    // Helper method to create test account data
    public static Account createTestAccount(String id, String name, String priority) {
        return new Account(
            Id = id,
            Name = name,
            CustomerPriority__c = priority
        );
    }
    
    // Helper method to create test account data with default priority
    public static Account createTestAccount(String name, String priority) {
        return new Account(
            Id = '0013H000006Vh9BQAS',
            Name = name,
            CustomerPriority__c = priority
        );
    }
    
    // Helper method to create test account data with default values
    public static Account createTestAccount(String name) {
        return new Account(
            Id = '0013H000006Vh9BQAS',
            Name = name,
            CustomerPriority__c = 'High'
        );
    }
    
    // Helper method to create test opportunity line item data
    public static OpportunityLineItem createTestOpportunityLineItem(String id, String opportunityId, Boolean confirmed, Boolean riskFlag) {
        return new OpportunityLineItem(
            Id = id,
            OpportunityId = opportunityId,
            Confirmed__c = confirmed,
            RiskFlag__c = riskFlag
        );
    }
    
    // Helper method to create test opportunity line item data with default values and custom opportunity ID
    public static OpportunityLineItem createTestOpportunityLineItem(String opportunityId) {
        return new OpportunityLineItem(
            Id = '00k000000000001',
            OpportunityId = opportunityId,
            Confirmed__c = true,
            RiskFlag__c = false
        );
    }
    
    // Helper method to create test task data
    public static Task createTestTask(String id, String whatId, String subject, String status, String priority) {
        return new Task(
            Id = id,
            WhatId = whatId,
            Subject = subject,
            Status = status,
            Priority = priority
        );
    }
    
    // Helper method to create test task data with default ID
    public static Task createTestTask(String whatId, String subject, String status, String priority) {
        return new Task(
            Id = '00T000000000001',
            WhatId = whatId,
            Subject = subject,
            Status = status,
            Priority = priority
        );
    }
    
    // Helper method to create test task data with default ID and status
    public static Task createTestTask(String whatId, String subject) {
        return new Task(
            Id = '00T000000000001',
            WhatId = whatId,
            Subject = subject,
            Status = 'In Progress',
            Priority = 'Low'
        );
    }
    
    // Helper method to create test task data with default ID, status, and priority
    public static Task createTestTask(String whatId) {
        return new Task(
            Id = '00T000000000001',
            WhatId = whatId,
            Subject = 'At Risk',
            Status = 'In Progress',
            Priority = 'Low'
        );
    }
    
    // Helper methods to create IDs with proper prefixes
    public static String createOpportunityId(String suffix) {
        return OPP_KEY_PREFIX + suffix;
    }
    
    public static String createAccountId(String suffix) {
        return ACC_KEY_PREFIX + suffix;
    }
    
    public static String createOpportunityLineItemId(String suffix) {
        return '00k' + suffix;
    }
    
    public static String createTaskId(String suffix) {
        return '00T' + suffix;
    }
    
    // Generic ID creation methods with default values
    public static String createGenericOpportunityId() {
        return mockObjectId(OPP_KEY_PREFIX);
    }
    
    public static String createGenericAccountId() {
        return ACC_KEY_PREFIX + '000000000001';
    }
    
    public static String createGenericOpportunityLineItemId() {
        return '00k000000000001';
    }
    
    public static String createGenericTaskId() {
        return '00T000000000001';
    }

    private static Integer counterIds = 0;
    public static String mockObjectId(String prefix) {

        counterIds++;

        String numberPart = String.valueOf(counterIds).leftPad(12, '0');
        return Id.valueOf(prefix + numberPart + 'AAA');
        
    }



   

}
