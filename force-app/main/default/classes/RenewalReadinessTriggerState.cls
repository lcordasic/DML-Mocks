public class RenewalReadinessTriggerState {
    private static Set<Id> oppIdsToRecalc = new Set<Id>();

    public static void collectOppsNeedingRecalc(List<Opportunity> news, Map<Id, Opportunity> oldMap) {
        if (news == null || oldMap == null) return;
        for (Opportunity o : news) {
            Opportunity oldO = oldMap.get(o.Id);
            if (oldO == null) continue;

            Boolean changed =
                o.CloseDate != oldO.CloseDate ||
                o.StageName != oldO.StageName ||
                o.Amount != oldO.Amount;

            if (changed && o.Type == 'Renewal' && o.IsClosed == false) oppIdsToRecalc.add(o.Id);
        }
    }

    public static Set<Id> drainOppsNeedingRecalc() {
        Set<Id> out = new Set<Id>();
        out.addAll(oppIdsToRecalc);
        oppIdsToRecalc.clear();
        return out;
    }
}