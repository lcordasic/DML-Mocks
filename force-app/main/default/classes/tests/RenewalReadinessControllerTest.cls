@isTest
public class RenewalReadinessControllerTest {
    // Mock DAOs to isolate controller logic and avoid real DML/SOQL
    private class MockOpportunityDAO extends RenewalReadinessController.OpportunityDAO {
        Opportunity opp;
        public MockOpportunityDAO(Opportunity o) { this.opp = o; }
        public override Opportunity getOpportunityById(Id opportunityId) {
            return opp;
        }
    }
    private class MockOpportunityLineItemDAO extends RenewalReadinessController.OpportunityLineItemDAO {
        List<OpportunityLineItem> olis;
        Integer updateCalls = 0;
        public MockOpportunityLineItemDAO(List<OpportunityLineItem> items) { this.olis = items; }
        public override List<OpportunityLineItem> getOpportunityLineItemsByOpportunityId(Id opportunityId) {
            return olis;
        }
        public override void dmlUpdate(List<OpportunityLineItem> items) {
            // Do not perform real DML. Capture call for assertions.
            updateCalls++;
        }
    }

    @isTest
    static void testLoadReturnsDTO() {
        // Arrange test data with TestDataReader
        Opportunity opp = TestDataReader.createTestOpportunity('Test Opp');
        opp.RenewalReadinessStatus__c = 'Green';
        opp.RenewalHealthScore__c = 90;

        OpportunityLineItem oli1 = TestDataReader.createTestOpportunityLineItem(opp.Id);
        oli1.Confirmed__c = true;
        oli1.RiskFlag__c = false;
        oli1.RiskReason__c = null;

        OpportunityLineItem oli2 = TestDataReader.createTestOpportunityLineItem(opp.Id);
        oli2.Confirmed__c = false;
        oli2.RiskFlag__c = true;
        oli2.RiskReason__c = 'Missing PO';

        // Inject mocks
        RenewalReadinessController.setDAOsForTest(
            new MockOpportunityDAO(opp),
            new MockOpportunityLineItemDAO(new List<OpportunityLineItem>{ oli1, oli2 })
        );

        // Act
        RenewalReadinessController.ReadinessDTO dto = RenewalReadinessController.load(opp.Id);

        // Assert
        System.assertEquals(opp.Id, dto.opportunityId, 'Should set opportunityId on DTO');
        System.assertEquals(Integer.valueOf(opp.RenewalHealthScore__c), dto.score, 'Should map score correctly');
        System.assertEquals(opp.RenewalReadinessStatus__c, dto.status, 'Should map status correctly');
        System.assertEquals(2, dto.lineItems.size(), 'Should return 2 line items');

        // Validate first line item mapping
        RenewalReadinessController.LineItemRow row1 = dto.lineItems[0];
        System.assertEquals(oli1.Id, row1.id);
        System.assertEquals(true, row1.confirmed);
        System.assertEquals(false, row1.riskFlag);
        System.assertEquals(null, row1.riskReason);
    }

    @isTest
    static void testSaveDelegatesDmlToDaoAndReloads() {
        // Arrange base data
        Opportunity opp = TestDataReader.createTestOpportunity('Test Opp 2');
        opp.RenewalReadinessStatus__c = 'Amber';
        opp.RenewalHealthScore__c = 70;

        OpportunityLineItem oli = TestDataReader.createTestOpportunityLineItem(opp.Id);
        oli.Confirmed__c = false;
        oli.RiskFlag__c = false;
        oli.RiskReason__c = null;

        // Prepare mocks
        MockOpportunityDAO oppDao = new MockOpportunityDAO(opp);
        MockOpportunityLineItemDAO oliDao = new MockOpportunityLineItemDAO(new List<OpportunityLineItem>{ oli });

        RenewalReadinessController.setDAOsForTest(oppDao, oliDao);

        // Prepare changes
        RenewalReadinessController.LineItemRow change = new RenewalReadinessController.LineItemRow();
        change.id = oli.Id;
        change.confirmed = true;
        change.riskFlag = true;
        change.riskReason = 'Updated Reason';

        Test.startTest();
        RenewalReadinessController.ReadinessDTO dto = RenewalReadinessController.save(opp.Id, new List<RenewalReadinessController.LineItemRow>{ change });
        Test.stopTest();

        // Assert the DAO update was invoked and DTO returned
        System.assertEquals(1, oliDao.updateCalls, 'Controller should delegate update to DAO');
        System.assertEquals(opp.Id, dto.opportunityId, 'Controller should return DTO from load after save');
        System.assertEquals(1, dto.lineItems.size(), 'DTO should contain line items from DAO reload');
    }

    @isTest
    static void testSaveNoChangesShortCircuitsToLoad() {
        Opportunity opp = TestDataReader.createTestOpportunity('Test Opp 3');
        opp.RenewalReadinessStatus__c = 'Red';
        opp.RenewalHealthScore__c = 40;

        OpportunityLineItem oli = TestDataReader.createTestOpportunityLineItem(opp.Id);

        MockOpportunityDAO oppDao = new MockOpportunityDAO(opp);
        MockOpportunityLineItemDAO oliDao = new MockOpportunityLineItemDAO(new List<OpportunityLineItem>{ oli });
        RenewalReadinessController.setDAOsForTest(oppDao, oliDao);

        // Act
        RenewalReadinessController.ReadinessDTO dto = RenewalReadinessController.save(opp.Id, new List<RenewalReadinessController.LineItemRow>());

        // Assert: no update call, load executed
        System.assertEquals(0, oliDao.updateCalls, 'No DML should be executed when there are no changes');
        System.assertEquals(opp.Id, dto.opportunityId, 'DTO should be returned from load');
        System.assertEquals(1, dto.lineItems.size(), 'DTO should contain items from DAO load');
    }
}
