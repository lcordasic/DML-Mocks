trigger OpportunityRenewalReadiness on Opportunity (before insert, after insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityRenewalReadinessHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityRenewalReadinessHandler.afterInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityRenewalReadinessHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityRenewalReadinessHandler.afterUpdate();
    }
}
