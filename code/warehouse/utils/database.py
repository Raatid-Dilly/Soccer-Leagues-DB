import os
import psycopg2
from dataclasses import dataclass
from contextlib import contextmanager

@dataclass
class DataBaseConnection():
    db_name: str
    user: str
    password: str
    host: str
    port: int = 5432
    
class DBWarehouse():
    def __init__(self, db_conn : DataBaseConnection):
        self.connection_url = f"postgresql://{db_conn.user}:{db_conn.password}@{db_conn.host}:{db_conn.port}/{db_conn.db_name}"
    
    @contextmanager
    def cursor(self):
        self.conn = psycopg2.connect(self.connection_url)
        self.conn.autocommit = True
        self.cur = self.conn.cursor()
        try:
            yield self.cur
        finally:
            self.cur.close()
            self.conn.close()

def get_credentials():
    return DataBaseConnection(
        db_name= os.getenv('PG_DB',''),
        user = os.getenv('PG_USER', ''),
        password = os.getenv('PG_PASSWORD', ''),
        host = os.getenv('PG_HOST', ''),
        port= int(os.getenv('PG_PORT', 5432))
    )  


def read_sql_query(query):
    with DBWarehouse(get_credentials()).cursor() as cur:
        cur.execute(open(query, 'r').read())