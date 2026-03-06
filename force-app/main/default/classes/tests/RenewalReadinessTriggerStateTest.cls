@isTest
public class RenewalReadinessTriggerStateTest {
    
    @isTest
    static void testCollectOppsNeedingRecalcWithChanges() {
        // Create test opportunities
        Opportunity oldOpp = new Opportunity(
            Name = 'Old Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'Renewal',
            IsClosed = false
        );
        
        Opportunity newOpp = new Opportunity(
            Name = 'New Opportunity',
            CloseDate = Date.today().addDays(1), // Changed
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'Renewal',
            IsClosed = false
        );
        
        insert newOpp;
        
        // Create old map
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        oldMap.put(oldOpp.Id, oldOpp);
        
        // Test the method
        Test.startTest();
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(new List<Opportunity>{newOpp}, oldMap);
        Test.stopTest();
        
        // Verify that the opportunity ID was added to the set
        // Note: We can't directly access the static set, so we'll test by draining it
        Set<Id> drainedSet = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        System.assertTrue(drainedSet.contains(newOpp.Id));
    }
    
    @isTest
    static void testCollectOppsNeedingRecalcWithoutChanges() {
        // Create test opportunities with no changes
        Opportunity oldOpp = new Opportunity(
            Name = 'Old Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'Renewal',
            IsClosed = false
        );
        
        Opportunity newOpp = new Opportunity(
            Name = 'New Opportunity',
            CloseDate = Date.today(), // Same as old
            StageName = 'Prospecting', // Same as old
            Amount = 10000, // Same as old
            Type = 'Renewal',
            IsClosed = false
        );
        
        insert newOpp;
        
        // Create old map
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        oldMap.put(oldOpp.Id, oldOpp);
        
        // Test the method
        Test.startTest();
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(new List<Opportunity>{newOpp}, oldMap);
        Test.stopTest();
        
        // Verify that the opportunity ID was NOT added to the set
        Set<Id> drainedSet = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        System.assertFalse(drainedSet.contains(newOpp.Id));
    }
    
    @isTest
    static void testCollectOppsNeedingRecalcWithNonRenewalOpportunity() {
        // Create test opportunities that are not renewals
        Opportunity oldOpp = new Opportunity(
            Name = 'Old Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'New Sale', // Not a renewal
            IsClosed = false
        );
        
        Opportunity newOpp = new Opportunity(
            Name = 'New Opportunity',
            CloseDate = Date.today().addDays(1), // Changed
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'New Sale', // Not a renewal
            IsClosed = false
        );
        
        insert newOpp;
        
        // Create old map
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        oldMap.put(oldOpp.Id, oldOpp);
        
        // Test the method
        Test.startTest();
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(new List<Opportunity>{newOpp}, oldMap);
        Test.stopTest();
        
        // Verify that the opportunity ID was NOT added to the set (because it's not a renewal)
        Set<Id> drainedSet = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        System.assertFalse(drainedSet.contains(newOpp.Id));
    }
    
    @isTest
    static void testDrainOppsNeedingRecalc() {
        // Add some IDs to the static set
        Opportunity opp1 = new Opportunity(
            Name = 'Opportunity 1',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'Renewal',
            IsClosed = false
        );
        
        Opportunity opp2 = new Opportunity(
            Name = 'Opportunity 2',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            Amount = 10000,
            Type = 'Renewal',
            IsClosed = false
        );
        
        insert new List<Opportunity>{opp1, opp2};
        
        // Manually add to the static set (simulating what would happen in a trigger)
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(new List<Opportunity>{opp1}, new Map<Id, Opportunity>());
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(new List<Opportunity>{opp2}, new Map<Id, Opportunity>());
        
        // Drain the set
        Test.startTest();
        Set<Id> drainedSet = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        Test.stopTest();
        
        // Verify that the set was drained and cleared
        System.assertTrue(drainedSet.contains(opp1.Id));
        System.assertTrue(drainedSet.contains(opp2.Id));
        System.assertEquals(2, drainedSet.size());
        
        // Verify that the set is now empty
        Set<Id> secondDrain = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        System.assertEquals(0, secondDrain.size());
    }
    
    @isTest
    static void testCollectOppsNeedingRecalcNullInputs() {
        // Test with null inputs
        Test.startTest();
        RenewalReadinessTriggerState.collectOppsNeedingRecalc(null, null);
        Test.stopTest();
        
        // Should not throw any exceptions
        Set<Id> drainedSet = RenewalReadinessTriggerState.drainOppsNeedingRecalc();
        System.assertEquals(0, drainedSet.size());
    }
}
