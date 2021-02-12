-- FUNCTION: league.getbatvsbowlstats(text, text)

-- DROP FUNCTION league.getbatvsbowlstats(text, text);

CREATE OR REPLACE FUNCTION league.getbatvsbowlstats(
	batsman text DEFAULT NULL, bowler text DEFAULT NULL)
    RETURNS TABLE(batsmanid bigint, bowlerid bigint, matchid integer, over integer, ball integer, wide integer, bye integer, legbye integer, noball integer, penalty integer, batsmanruns integer, dismissal bigint, sumruns bigint, wicket bigint, ballcount bigint, batsmanstrikerate numeric, bowlerstrikerate numeric, prevbatsmanstrikerate numeric, prevbowlerstrikerate numeric, decision text) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
    
AS $BODY$
DECLARE
		bowl_id bigint DEFAULT 0;
		bats_id bigint DEFAULT 0;
	BEGIN
		IF (batsman IS NOT NULL AND bowler IS NOT NULL) THEN
			SELECT player_id FROM league."Players" WHERE player_name = batsman into bats_id;
			SELECT player_id FROM league."Players" WHERE player_name = bowler into bowl_id;
		END IF;
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
					WHERE (bowl_id = 0 OR d.bowler_id = bowl_id) AND 
						(bats_id = 0 OR d.batsman_id=bats_id)
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
				dis.dismissal_id,
				sro.runs_sum,
				sro.wicket,
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
			LEFT JOIN league.dismissals dis ON dis.dismissal = sro.dismissal_kind
			ORDER BY sro.match_id, sro.over, sro.ball;
	END;
$BODY$;

ALTER FUNCTION league.getbatvsbowlstats(text, text)
    OWNER TO postgres;
