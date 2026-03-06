trigger OpportunityLineItemRenewalReadiness on OpportunityLineItem (
    before update,
    after insert,
    after update,
    after delete
) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Use the currently present handler class (OppyLineItemRenewalReadinessHandler)
        OppyLineItemRenewalReadinessHandler.beforeUpdate(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        OppyLineItemRenewalReadinessHandler.afterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        OppyLineItemRenewalReadinessHandler.afterUpdate(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        OppyLineItemRenewalReadinessHandler.afterDelete(Trigger.old);
    }
}
