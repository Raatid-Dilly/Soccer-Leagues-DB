import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

import pandas as pd
import numpy as np
import requests
import argparse
import credentials
import os
from warehouse.utils.database import DBWarehouse, get_credentials, read_sql_query
from sqlalchemy import create_engine
from sqlalchemy.types import *

WORKDIR = os.environ.get('WORKDIR', '/app')

class Soccer():
    """
    
    """
    def __init__(self, season):
        self.season = season
        self.url = 'https://api-football-v1.p.rapidapi.com/v3/'
        self.headers = credentials.API_KEY_HOST
        self.conn_url = DBWarehouse(get_credentials()).connection_url
        self.engine = create_engine(self.conn_url)
        self.conn = self.engine.connect()
        self.leagues = []
        self.teams = []
        self._get_leagues()
        self._get_teams()
        self.players = self._get_squads()
        self.standings = self._standings()
        self.team_statistics = self._get_team_stats()
        self.player_stats = self._get_player_stats()
        self.topscorers = self._top_scorers()
        #self.fixtures = self._get_fixtures()
        #self.team_fixture_stats = self._team_stats_by_fixture()

    def _get_leagues(self):
        endpoint = 'leagues'
        r = requests.get(self.url + endpoint, headers=self.headers)
        all_leagues=[(lg['league']['id'], lg['league']['name'], lg['country']['name'],
                        lg['country']['code']) for lg in r.json().get('response', [])]
        leagues_to_get = [39, 61, 78, 135, 140, 94, 88, 262, 71, 253]
        for league in all_leagues:
            if league[0] not in leagues_to_get:
                continue
            self.leagues.append(league)
        seasons = [self.season]
        seasons_df = pd.DataFrame(seasons, columns=['season'])
        leagues_df = pd.DataFrame(self.leagues, columns=['league_id', 'league_name', 'country', 'country_code'])
        seasons_df.to_sql('seasons', con=self.conn, if_exists='append', index=False)
        leagues_df.to_sql('temp_leagues', con=self.conn, if_exists='append', index=False)
        return self.leagues
    
    def _standings(self):
        endpoint = 'standings'
        params = {'season': f'{self.season}'}
        standings = pd.DataFrame()
        for league in self.leagues:
            params['league'] = league[0]
            r = requests.get(self.url + endpoint, headers=self.headers, params=params)
            data = pd.json_normalize(r.json().get('response', [])[0].get('league', {}).get('standings', [])[0],
            meta=[['league', 'id'], ['league', 'name']], sep='_')
            data = data.drop(['group', 'status', 'update', 'team_logo', 'form', 'all_played'], axis=1)
            data['league_id'] = league[0]
            standings = pd.concat([standings, data])
        cols = standings.columns.tolist()
        standings = standings[cols[5:7] + cols[:5] + cols[7:]]
        standings['season'] = self.season
        standings.to_sql('temp_standings', con=self.conn, if_exists='append', index=False)
        return standings
    
    def _get_teams(self):
        teams_schema = {'team_id' : String(10), 'team_name': String(50), 'team_code': String(5), 'league_id': String(10) }
        endpoint = 'teams'
        params = {'season' : f'{self.season}'}
        for league in self.leagues:
            params['league'] = league[0]
            r = requests.get(self.url + endpoint, headers=self.headers, params=params)
            data = r.json()
            for i in range(len(data['response'])):
                team_id = data['response'][i]['team']['id']
                team_name = data['response'][i]['team']['name']
                team_code = data['response'][i]['team']['code']
                league_id = league[0]
                self.teams.append((team_id, team_name, team_code, league_id))
        teams_df = pd.DataFrame(self.teams, columns=['team_id', 'team_name', 'team_code', 'league_id'])
        teams_df.to_sql('temp_teams', con=self.conn, if_exists='append', index=False, dtype=teams_schema)
        return self.teams

    def _get_team_stats(self):
        endpoint = 'teams/statistics'
        params = {'season': f'{self.season}'}
        teams_stats = pd.DataFrame()
        cols_to_drop = ['cards_yellow__total', 'cards_yellow__percentage', 'cards_red__total', 'cards_red__percentage']
        for team in self.teams:
            params['team']=team[0]
            params['league']=team[3]
            r = requests.get(self.url+endpoint, headers=self.headers, params=params)
            data = pd.json_normalize(r.json().get('response', {}), sep='_')
            for column_name in cols_to_drop:
                if column_name in data.columns:
                    data = data.drop(column_name, axis= 1)
                continue
            teams_stats = pd.concat([teams_stats, data])
        teams_stats = teams_stats.drop(['form', 'lineups', 'league_logo', 'league_flag', 'team_logo'], axis=1)
        for col in teams_stats:
            if col.endswith('percentage'):
                teams_stats[col] = teams_stats[col].str.replace('%', '').fillna(np.nan).astype('float')
        teams_stats.to_sql('temp_team_stats', con=self.conn, if_exists='append', index=False)
        return teams_stats 

    def _get_squads(self):    
        endpoint = 'players'
        params = {'season': f'{self.season}'}
        players=pd.DataFrame()
        for team in self.teams:
            params['team'] = team[0]
            params['league'] = team[3]
            for i in range(1,4):
                params['page'] = i
                r = requests.get(self.url + endpoint, headers=self.headers, params=params)
                data = pd.json_normalize(r.json().get('response'), errors='ignore', sep='_')
                players = pd.concat([players, data])
        players = players.drop(['statistics', 'player_age', 'player_birth_place', 'player_birth_country', 'player_injured', 'player_photo'], axis=1).drop_duplicates(subset = 'player_id')
        players['player_height'] = players['player_height'].str.replace('cm', '').fillna(np.nan).astype('float')
        players['player_weight'] = players['player_weight'].str.replace('kg', '').fillna(np.nan).astype('float')
        players['player_birth_date']  = pd.to_datetime(players['player_birth_date'], yearfirst=True)
        self.players = players.values.tolist()
        players.to_sql('temp_players', con=self.conn, if_exists='append', index=False)
        return players

    def _get_player_stats(self):
        endpoint = 'players'
        params = {'season': f'{self.season}'} 
        player_stats = pd.DataFrame()
        for team in self.teams:
            params['team'] = team[0]
            params['league'] = team[3]
            for i in range(1, 4):
                params['page'] = i
                r = requests.get(self.url + endpoint, headers=self.headers, params=params)
                data = pd.json_normalize(r.json().get('response'), record_path='statistics', meta=[['player', 'id'], ['player', 'name']], errors='ignore', sep='_')
                player_stats = pd.concat([player_stats, data])
        player_stats = player_stats.drop(['team_logo', 'league_logo', 'league_flag', ], axis=1)
        cols = player_stats.columns.tolist()
        cols = cols[-2:] + cols[:-2]
        player_stats = player_stats[cols].drop_duplicates()
        player_stats.to_sql('temp_player_stats', con=self.conn, if_exists='append', index=False)
        return player_stats
    
    def _top_scorers(self):
        endpoint='players/topscorers'
        params={'season': f'{self.season}'}
        scorers = pd.DataFrame()
        for league in self.leagues:
            params['league'] = league[0]
            r=requests.get(self.url + endpoint, headers=self.headers, params=params)
            data=pd.json_normalize(r.json().get('response', []), record_path='statistics', meta=[['player', 'id'], ['player', 'name']], errors='ignore', sep='_')
            data = data.drop(['league_logo', 'team_logo','league_flag', 'games_lineups', 'games_minutes', 'games_number', 'games_captain', 'substitutes_in', 'substitutes_out', 'substitutes_bench', 'goals_conceded', 'goals_saves', 'passes_total', 'passes_key', 'passes_accuracy', 'tackles_total', 'tackles_blocks', 'tackles_interceptions', 'duels_total', 'duels_won','dribbles_attempts', 'dribbles_success', 'dribbles_past', 'fouls_drawn', 'fouls_committed', 'cards_yellow', 'cards_yellowred', 'cards_red', 'penalty_won', 'penalty_commited', 'penalty_saved', 'games_position'], axis=1).drop_duplicates()
            data['rank'] = [_ for _ in range(1, (len(data)+1))]  
            scorers = pd.concat([scorers, data])
        cols = scorers.columns.tolist()
        cols = cols[-3:] + cols[:-3]
        scorers = scorers[cols]
        scorers.to_sql('temp_topscorers', con=self.conn, if_exists='append', index=False)
        return scorers

    def _get_fixtures(self):
        endpoint = 'fixtures'
        params = {'season': f'{self.season}'}
        fixtures_table = pd.DataFrame()
        for league in self.leagues:
            params['league'] = league[0]
            r = requests.get(self.url + endpoint, headers=self.headers, params=params)
            data = pd.json_normalize(r.json().get('response', []), sep='_')
            data = data.drop(columns=['fixture_timezone', 'fixture_periods_first', 'fixture_periods_second', 'fixture_status_long', 'fixture_status_short', 'fixture_status_elapsed', 'league_logo', 'league_flag', 'teams_home_logo', 'teams_away_logo', 'fixture_timestamp', 'score_extratime_home', 'score_extratime_away', 'score_penalty_home', 'score_penalty_away'])
            fixtures_table = pd.concat([fixtures_table, data])     
        fixtures_table.to_sql('temp_league_fixtures', con=self.conn, if_exists='append', index=False)
        return fixtures_table

    def _team_stats_by_fixture(self):
        stats_by_fixtures_schema = {}
        endpoint = 'fixtures/statistics'
        params= {}
        team_fixture_stats = pd.DataFrame()
        for fixture in self.fixtures['fixture_id'].to_list():
            params['fixture'] = fixture
            r = requests.get(self.url + endpoint, headers=self.headers, params=params)
            data = pd.json_normalize(r.json().get('response'), record_path='statistics', meta=[['team', 'id'], ['team', 'name']], errors='ignore', sep='_')
            data['fixture_id'] = fixture
            data = data.pivot(index=['fixture_id', 'team_id', 'team_name'], columns='type', values='value')
            team_fixture_stats = pd.concat([team_fixture_stats, data])
        team_fixture_stats.columns = ['Ball Possession %' if col=='Ball Possession' else col for col in team_fixture_stats.columns]
        team_fixture_stats[['Ball Possession %', 'Passes %']] = team_fixture_stats[['Ball Possession %', 'Passes %']].apply(lambda x: x.str.rstrip('%')).astype('float')
        for column in team_fixture_stats.columns:
            if column in ['fixture_id', 'team_id', 'team_name']:
                stats_by_fixtures_schema[column] = String(30)
            else:
                stats_by_fixtures_schema[column] = Integer
        team_fixture_stats.to_sql('temp_fixtures_stats_teams', con=self.conn, if_exists='append', index=True)
        return team_fixture_stats  

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Year')
    parser.add_argument('--year', type=int, help='Beginning year of league season', required=True)
    args = parser.parse_args()
    read_sql_query(f'{WORKDIR}/code/warehouse/sql/setup_db.sql')
    for year in range(args.year, 2022):
        Soccer(year)
    sql_files = [f'{WORKDIR}/code/warehouse/sql/insert_tables.sql', f'{WORKDIR}/code/warehouse/sql/create_views.sql']
    for file in sql_files:
        read_sql_query(file)

