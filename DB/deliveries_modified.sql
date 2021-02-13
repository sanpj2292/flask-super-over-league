DROP TABLE DeliveriesModified;
SELECT 
    batsman_id,
    bowler_id,
	delivery_id,
    CASE WHEN dismissal_kind IS NULL OR COALESCE(TRIM(dismissal_kind), '') = '' THEN
        CASE 
			WHEN batsman_runs = 0 and extra_runs <= 0 AND dismissal_kind IS NULL THEN 0::text
			WHEN batsman_runs > 0 and (extra_runs IS NULL or extra_runs < 1) AND dismissal_kind IS NULL THEN batsman_runs::text
			WHEN legbye_runs > 0 THEN legbye_runs::text || 'LB'
			WHEN bye_runs > 0 THEN bye_runs::text || 'B'
			WHEN wide_runs > 0 THEN wide_runs::text || 'W'
			WHEN noball_runs > 0 THEN total_runs::text || 'NB'
			WHEN penalty_runs > 0 THEN penalty_runs::text || 'PEN'
		ELSE
			'NoDecision'
		END
	ELSE
		dismissal_kind
    END decision
INTO TEMP TABLE DeliveriesModified
FROM league."Deliveries";

SELECT d.* FROM DeliveriesModified dm
INNER JOIN league."Deliveries" d ON dm.delivery_id = d.delivery_id
WHERE dm.decision='NoDecision';