public class ReadinessCalculator {
    public class Result {
        public Integer score;
        public String status;
        public Result(Integer s, String st) { score = s; status = st; }
    }

    public static Result calculate(String priority, Date closeDate, List<OpportunityLineItem> olis) {
        Integer score = 50;

        Integer confirmed = 0;
        Integer risk = 0;
        Boolean anyRiskBlankReason = false;

        if (olis != null) {
            for (OpportunityLineItem li : olis) {
                if (li.Confirmed__c == true) confirmed++;
                if (li.RiskFlag__c == true) {
                    risk++;
                    if (String.isBlank(li.RiskReason__c)) anyRiskBlankReason = true;
                }
            }
        }

        score += Math.min(confirmed * 10, 30);
        score -= Math.min(risk * 15, 45);
        if (risk > 0 && anyRiskBlankReason) score -= 10;

        if (priority == 'High') score += 10;
        else if (priority == 'Medium') score += 5;

        Date urgentCutoff = Date.today().addDays(14);
        if (closeDate != null && closeDate <= urgentCutoff && score < 60) score -= 10;

        score = Math.max(0, Math.min(100, score));

        String status =
            (score >= 80) ? 'Green' :
            (score >= 50) ? 'Amber' : 'Red';

        return new Result(score, status);
    }
}
