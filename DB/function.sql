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

		return query 
			select 
				d.batsman_id, d.bowler_id, 
				COUNT(d.ball) as balls_faced
				,SUM(CASE WHEN batsman_runs = 0 and extra_runs <= 0 THEN 1 ELSE 0 END) as dots,
				SUM(CASE WHEN batsman_runs = 1 THEN 1 ELSE 0 END) as singles,
				SUM(CASE WHEN batsman_runs = 2 THEN 1 ELSE 0 END) as twos,
				SUM(CASE WHEN batsman_runs = 3 THEN 1 ELSE 0 END) as threes,
				SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) as boundaries,
				SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) as sixes,
				SUM(CASE WHEN extra_runs > 0 THEN 1 ELSE 0 END) as extras,
				SUM(CASE WHEN (dismissal_kind != 'retired hurt' OR 
						dismissal_kind != 'run out' OR
						dismissal_kind != 'obstructing the field') AND 
						dismissal_kind IS NOT NULL THEN 1 ELSE 0 END) as wickets_for_bowler,
				SUM(CASE WHEN dismissal_kind = 'run out' THEN 1 ELSE 0 END) as runouts,
				SUM(CASE WHEN dismissal_kind = 'hit wicket' THEN 1 ELSE 0 END) as hitwicket,
				SUM(CASE WHEN dismissal_kind = 'obstructing the field' THEN 1 ELSE 0 END) as obstruction
			from league."Deliveries" d where d.batsman_id = bats_id and d.bowler_id = bowl_id
			group by d.batsman_id, d.bowler_id;
	END;
$$