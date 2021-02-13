CREATE OR REPLACE FUNCTION league.GetBatVsBowlDetails (BATSMAN text, BOWLER text) 
	returns table (
		batsman_id bigint,
		bowler_id bigint,
		balls_faced bigint
	) LANGUAGE PLPGSQL AS $$
	DECLARE
		bowl_id bigint;
		bats_id bigint;
	BEGIN
		SELECT player_id FROM league."Players" WHERE player_name = batsman into bats_id;
		SELECT player_id FROM league."Players" WHERE player_name = bowler into bowl_id;

		WITH strike_rate_out as (
			SELECT 
				*,
				ROUND((100 * del.runs_sum::NUMERIC / del.BallCount), 2) batsman_strike_rate
				,ROUND((del.BallCount::NUMERIC / CASE WHEN del.wicket = 0 THEN 1 ELSE del.wicket END),2) bowler_strike_rate
			FROM (
				SELECT 
					*,
					(SUM(d.batsman_runs) OVER (
							PARTITION BY d.batsman_id, d.bowler_id
							ORDER BY d.match_id, d.over, d.ball)) AS runs_sum,
					(SUM(CASE WHEN d.dismissal_kind IS NULL AND COALESCE(TRIM(d.dismissal_kind), '') = '' THEN 0 ELSE 1 END)
						OVER (
							PARTITION BY d.batsman_id, d.bowler_id
							ORDER BY d.match_id, d.over, d.ball)) AS wicket,
					RANK() OVER (PARTITION BY d.batsman_id, d.bowler_id ORDER BY d.match_id, d.over, d.ball) AS BallCount
				FROM league."Deliveries" d
				WHERE d.bowler_id = 176 AND d.batsman_id=478
				ORDER BY d.match_id, d.over, d.ball
			) del
			ORDER BY del.match_id, del.over, del.ball
		)


		return query 
			SELECT batsman_id,bowler_id,match_id,
				over,ball,
				batsman_runs,
				BallCount,
				batsman_strike_rate,
				bowler_strike_rate,
				LAG(batsman_strike_rate, 1) OVER(ORDER BY match_id, over, ball) AS prev_batsman_strike_rate,
				LAG(bowler_strike_rate, 1) OVER(ORDER BY match_id, over, ball) AS prev_bowler_strike_rate,
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
			FROM strike_rate_out
			ORDER BY match_id, over, ball;
	END;
$$