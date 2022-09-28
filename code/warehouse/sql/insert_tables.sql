--Insert Seasons
INSERT into soccer.Seasons
Select season from public.seasons;

--(Leagues) Inserts Leagues from temp_leagues table
INSERT INTO soccer.Leagues
SELECT * FROM public.temp_leagues
ON CONFLICT(id) DO NOTHING;

--(Teams) Inserts Teams from temp_teams table
INSERT INTO soccer.Teams
SELECT * FROM public.temp_teams
ON CONFLICT (id) DO NOTHING;

--(Players) Inserts Players from temp_players table
INSERT INTO soccer.Players
SELECT * FROM public.temp_players
ON CONFLICT (id) DO NOTHING;


--(Team Stats) Inserts Team Statistics from temp_team_stats table
ALTER TABLE public.temp_team_stats
	ALTER COLUMN goals_for_average_home TYPE NUMERIC USING (goals_for_average_home::numeric),
	ALTER COLUMN goals_for_average_away TYPE NUMERIC USING (goals_for_average_away::numeric),
	ALTER COLUMN goals_for_average_total TYPE NUMERIC USING (goals_for_average_total::numeric),
	ALTER COLUMN goals_against_average_home TYPE NUMERIC USING (goals_for_average_home::numeric),
	ALTER COLUMN goals_against_average_away TYPE NUMERIC USING (goals_for_average_away::numeric),
	ALTER COLUMN goals_against_average_total TYPE NUMERIC USING (goals_for_average_total::numeric),
	ALTER COLUMN "goals_for_minute_106-120_total" TYPE INTEGER USING ("goals_for_minute_106-120_total"::integer),
	ALTER COLUMN "goals_against_minute_106-120_total" TYPE INTEGER USING ("goals_against_minute_106-120_total"::integer),
	ALTER COLUMN "cards_yellow_91-105_total" TYPE INTEGER USING ("cards_yellow_91-105_total"::integer),
	ALTER COLUMN "cards_yellow_106-120_total" TYPE INTEGER USING ("cards_yellow_106-120_total"::integer),
	ALTER COLUMN "cards_red_91-105_total" TYPE INTEGER USING ("cards_red_91-105_total"::integer),
	ALTER COLUMN "cards_red_106-120_total" TYPE INTEGER USING ("cards_red_106-120_total"::integer);


INSERT INTO soccer.Team_Statistics
SELECT 
	league_season, team_id, team_name, league_id, league_name, league_country, fixtures_played_home, fixtures_played_away, fixtures_played_total,
    fixtures_wins_home, fixtures_wins_away, fixtures_wins_total, fixtures_draws_home, fixtures_draws_away, fixtures_draws_total,
    fixtures_loses_home, fixtures_loses_away, fixtures_loses_total, goals_for_total_home, goals_for_total_away,goals_for_total_total,
    goals_for_average_home, goals_for_average_away, goals_for_average_total, "goals_for_minute_0-15_total", "goals_for_minute_0-15_percentage",
    "goals_for_minute_16-30_total", "goals_for_minute_16-30_percentage", "goals_for_minute_31-45_total", "goals_for_minute_31-45_percentage",
    "goals_for_minute_46-60_total", "goals_for_minute_46-60_percentage", "goals_for_minute_61-75_total", "goals_for_minute_61-75_percentage",
    "goals_for_minute_76-90_total", "goals_for_minute_76-90_percentage", "goals_for_minute_91-105_total", "goals_for_minute_91-105_percentage",
    "goals_for_minute_106-120_total", "goals_for_minute_106-120_percentage", goals_against_total_home, goals_against_total_away, goals_against_total_total,
    goals_against_average_home, goals_against_average_away, goals_against_average_total, "goals_against_minute_0-15_total", "goals_against_minute_0-15_percentage",
    "goals_against_minute_16-30_total", "goals_against_minute_16-30_percentage", "goals_against_minute_31-45_total", "goals_against_minute_31-45_percentage",
    "goals_against_minute_46-60_total", "goals_against_minute_46-60_percentage", "goals_against_minute_61-75_total", "goals_against_minute_61-75_percentage",
    "goals_against_minute_76-90_total","goals_against_minute_76-90_percentage", "goals_against_minute_91-105_total", "goals_against_minute_91-105_percentage",
    "goals_against_minute_106-120_total", "goals_against_minute_106-120_percentage", biggest_streak_wins, biggest_streak_draws, biggest_streak_loses,
    biggest_wins_home, biggest_wins_away, biggest_loses_home, biggest_loses_away, biggest_goals_for_home, biggest_goals_for_away, biggest_goals_against_home,
    biggest_goals_against_away, clean_sheet_home, clean_sheet_away, clean_sheet_total, failed_to_score_home, failed_to_score_away, failed_to_score_total,
    penalty_scored_total, penalty_scored_percentage, penalty_missed_total, penalty_missed_percentage, penalty_total, "cards_yellow_0-15_total", "cards_yellow_0-15_percentage",
    "cards_yellow_16-30_total", "cards_yellow_16-30_percentage", "cards_yellow_31-45_total", "cards_yellow_31-45_percentage", "cards_yellow_46-60_total",
    "cards_yellow_46-60_percentage", "cards_yellow_61-75_total", "cards_yellow_61-75_percentage", "cards_yellow_76-90_total", "cards_yellow_76-90_percentage",
    "cards_yellow_91-105_total", "cards_yellow_91-105_percentage", "cards_yellow_106-120_total", "cards_yellow_106-120_percentage", "cards_red_0-15_total",
    "cards_red_0-15_percentage", "cards_red_16-30_total", "cards_red_16-30_percentage", "cards_red_31-45_total", "cards_red_31-45_percentage","cards_red_46-60_total",
    "cards_red_46-60_percentage", "cards_red_61-75_total", "cards_red_61-75_percentage", "cards_red_76-90_total", "cards_red_76-90_percentage", "cards_red_91-105_total","cards_red_91-105_percentage",
    "cards_red_106-120_total", "cards_red_106-120_percentage"
FROM public.temp_team_stats;


--(Standings) Inserts Standings from temp_standings table
ALTER TABLE soccer.standings
	ALTER COLUMN team_id TYPE VARCHAR,
	ALTER COLUMN league_id TYPE VARCHAR;

INSERT INTO soccer.Standings (team_id, team_name, rank, points, "goalsDiff", description, season, league_id) 
SELECT team_id, team_name, rank, points, "goalsDiff", description, season, league_id 
FROM public.temp_standings;


--(Topscorers) Inserts Topscorers from temp_topscorers table
ALTER TABLE public.temp_topscorers ALTER COLUMN games_rating TYPE NUMERIC USING (games_rating::numeric);

INSERT INTO soccer.Topscorers
SELECT * FROM public.temp_topscorers;

--(Player Stats) Inserts Player_Stats from temp_player_stats table
ALTER TABLE public.temp_player_stats 
    ALTER COLUMN games_rating TYPE NUMERIC USING (games_rating::numeric),
    ALTER COLUMN goals_conceded TYPE NUMERIC USING (goals_conceded::numeric),
    ALTER COLUMN passes_total TYPE numeric USING (passes_total::numeric),
    ALTER COLUMN passes_accuracy TYPE numeric USING (passes_accuracy::numeric),
    ALTER COLUMN duels_won TYPE numeric USING (duels_won::numeric),
    ALTER COLUMN duels_total TYPE numeric USING (duels_total::numeric),
    ALTER COLUMN dribbles_attempts TYPE numeric USING (dribbles_attempts::numeric),
    ALTER COLUMN fouls_drawn TYPE numeric USING (fouls_drawn::numeric),
    ALTER COLUMN fouls_committed TYPE numeric USING (fouls_committed::numeric),
    ALTER COLUMN penalty_scored TYPE numeric USING (penalty_scored::numeric),
    ALTER COLUMN penalty_missed TYPE numeric USING (penalty_missed::numeric),
    ALTER COLUMN shots_on TYPE numeric USING (shots_on::numeric),
    ALTER COLUMN goals_assists TYPE numeric USING (goals_assists::numeric),
    ALTER COLUMN tackles_blocks TYPE numeric USING (tackles_blocks::numeric),
    ALTER COLUMN tackles_interceptions TYPE numeric USING (tackles_interceptions::numeric),
    ALTER COLUMN penalty_saved TYPE numeric USING (penalty_saved::numeric),
    ALTER COLUMN shots_total TYPE numeric USING (shots_total::numeric),
    ALTER COLUMN passes_key TYPE numeric USING (passes_key::numeric),
    ALTER COLUMN tackles_total TYPE numeric USING (tackles_total::numeric),
    ALTER COLUMN dribbles_success TYPE numeric USING (dribbles_success::numeric),
    ALTER COLUMN dribbles_past TYPE numeric USING (dribbles_past::numeric),
    ALTER COLUMN penalty_won TYPE numeric USING (penalty_won::numeric),
    ALTER COLUMN penalty_commited TYPE numeric USING (penalty_commited::numeric);

ALTER TABLE soccer.Player_Stats
	ALTER COLUMN player_id TYPE VARCHAR,
	ALTER COLUMN team_id TYPE VARCHAR;

INSERT INTO soccer.Player_Stats (player_id, team_id, league_season, league_name, league_country, games_appearences, games_lineups, games_minutes, games_number, games_position, games_rating, games_captain, substitutes_in, substitutes_out, substitutes_bench, shots_total, shots_on, goals_total, goals_conceded,  goals_assists, goals_saves, passes_total, passes_key, passes_accuracy, tackles_total, tackles_blocks, tackles_interceptions, duels_total, duels_won, dribbles_attempts, dribbles_success, dribbles_past, fouls_drawn, fouls_committed, cards_yellow, cards_yellowred, cards_red, penalty_won, penalty_commited, penalty_scored,
penalty_missed, penalty_saved)
SELECT player_id, team_id, league_season, league_name, league_country, games_appearences, games_lineups, games_minutes, games_number, games_position, games_rating, 
    games_captain, substitutes_in, substitutes_out, substitutes_bench, shots_total, shots_on, goals_total, goals_conceded, 
    goals_assists, goals_saves, passes_total, passes_key, passes_accuracy, tackles_total, tackles_blocks, 
    tackles_interceptions, duels_total, duels_won, dribbles_attempts, dribbles_success, dribbles_past, fouls_drawn, 
    fouls_committed, cards_yellow, cards_yellowred, cards_red, penalty_won, penalty_commited, penalty_scored,
    penalty_missed, penalty_saved
FROM public.temp_player_stats;

--(Fixtures) Inserts from temp_league_fixtures table
/*
ALTER TABLE public.temp_league_fixtures
	ALTER COLUMN fixture_date TYPE TIMESTAMP USING (fixture_date::timestamp without time zone);

INSERT INTO soccer.Fixtures 
SELECT fixture_id, fixture_referee, fixture_date, fixture_venue_id, fixture_venue_name,
 	fixture_venue_city, league_id, league_season, teams_home_id, teams_home_winner,
    teams_away_id, teams_away_winner, goals_home, goals_away, score_halftime_home,
    score_halftime_away, score_fulltime_home,score_fulltime_away
FROM public.temp_league_fixtures
ON CONFLICT(id) DO NOTHING;


--Fixture Stats

INSERT INTO soccer.Fixture_Results (fixture_id, team_id, ball_possession_perc,
    blocked_shots, corner_Kicks, fouls, goalkeeper_saves, offsides, passes_perc,
    total_passes, accurate_passes, red_cards, yellow_cards,
    shots_insidebox, shots_off_goal, shots_on_goal,shots_outsidebox, total_shots)
select fixture_id, team_id, "Ball Possession %", "Blocked Shots", "Corner Kicks", "Fouls", 
	"Goalkeeper Saves", "Offsides", "Passes %",
    "Total passes", "Passes accurate", "Red Cards", "Yellow Cards",
    "Shots insidebox", "Shots off Goal", "Shots on Goal", "Shots outsidebox", "Total Shots"
from public.temp_fixtures_stats_teams
On CONFLICT do nothing;


DROP TABLE public.temp_leagues, public.temp_teams, public.temp_players, public.temp_team_stats,
public.temp_standings, public.temp_topscorers, public.temp_player_stats, public.temp_league_fixtures,
public.temp_fixtures_stats_teams;
*/