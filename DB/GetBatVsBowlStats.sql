DROP FUNCTION league.getbatvsbowlstats;

CREATE OR REPLACE FUNCTION league.GetBatVsBowlStats (BATSMAN text, BOWLER text) 
	returns table (
		batsmanId bigint,
		bowlerId bigint,
		matchId int,
        over int,
		ball int,
		wide int,
		bye int,
		legbye int,
		noball int,
		penalty int,
        batsmanRuns int,
		dismissal text,
		sumRuns bigint,
        BallCount bigint,
        batsmanStrikeRate NUMERIC,
        bowlerStrikeRate NUMERIC,
        prevBatsmanStrikeRate NUMERIC,
        prevBowlerStrikeRate NUMERIC,
        decision TEXT
	) LANGUAGE PLPGSQL AS $$
	DECLARE
		bowl_id bigint;
		bats_id bigint;
	BEGIN
		SELECT player_id FROM league."Players" WHERE player_name = batsman into bats_id;
		SELECT player_id FROM league."Players" WHERE player_name = bowler into bowl_id;

		


		return query 
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
					WHERE d.bowler_id = bowl_id AND d.batsman_id=bats_id
					ORDER BY d.match_id, d.over, d.ball
				) del
				ORDER BY del.match_id, del.over, del.ball
			)
			SELECT sro.batsman_id,sro.bowler_id,sro.match_id,
				sro.over,sro.ball,
				sro.wide_runs,
				sro.bye_runs,
				sro.legbye_runs,
				sro.noball_runs,
				sro.penalty_runs,
				sro.batsman_runs,
				sro.dismissal_kind,
				sro.runs_sum,
				sro.BallCount,
				sro.batsman_strike_rate,
				sro.bowler_strike_rate,
				LAG(batsman_strike_rate, 1, 0.00) OVER(ORDER BY sro.match_id, sro.over, sro.ball) AS prev_batsman_strike_rate,
				LAG(sro.bowler_strike_rate, 1, 0.00) OVER(ORDER BY sro.match_id, sro.over, sro.ball) AS prev_bowler_strike_rate,
				CASE WHEN sro.dismissal_kind IS NULL OR COALESCE(TRIM(sro.dismissal_kind), '') = '' THEN
					CASE 
						WHEN sro.batsman_runs = 0 and sro.extra_runs <= 0 AND sro.dismissal_kind IS NULL THEN 0::text
						WHEN sro.batsman_runs > 0 and (sro.extra_runs IS NULL or sro.extra_runs < 1) AND sro.dismissal_kind IS NULL THEN sro.batsman_runs::text
						WHEN sro.legbye_runs > 0 THEN sro.legbye_runs::text || 'LB'
						WHEN sro.bye_runs > 0 THEN sro.bye_runs::text || 'B'
						WHEN sro.wide_runs > 0 THEN sro.wide_runs::text || 'W'
						WHEN sro.noball_runs > 0 THEN sro.total_runs::text || 'NB'
						WHEN sro.penalty_runs > 0 THEN sro.penalty_runs::text || 'PEN'
					ELSE
						'NoDecision'
					END
				ELSE
					sro.dismissal_kind
				END decision
			FROM strike_rate_out sro
			ORDER BY sro.match_id, sro.over, sro.ball;
	END;
$$