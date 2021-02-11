from psycopg2 import connect, DatabaseError
from psycopg2.extras import RealDictCursor
import os

try:
    db_connection = connect(dbname='ipl', user='postgres', host='localhost', password=os.environ['POSTGRES_ACCOUNT_PWD'])
    db_cursor = db_connection.cursor(cursor_factory = RealDictCursor)
except (Exception, DatabaseError) as e:
    print(f'Error while connecting to postgres: {e}')