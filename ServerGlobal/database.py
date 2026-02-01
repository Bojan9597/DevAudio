import os
import platform
import psycopg2
from psycopg2.extras import RealDictCursor

class Database:
    def __init__(self):
        # On the server (Linux), connect to localhost
        # On local dev (Windows), connect to the remote DB
        if platform.system() == "Windows":
            self.host = "hope.global.ba"
        else:
            self.host = "localhost"
        self.database = "velorusb_echoHistory"
        self.user = "velorusb_echoHistoryAdmin"
        self.password = "Pijanista123!"
        self.port = 5432
        self.connection = None

    def connect(self):
        """Establishes a connection to the database."""
        try:
            self.connection = psycopg2.connect(
                host=self.host,
                database=self.database,
                user=self.user,
                password=self.password,
                port=self.port
            )
            return True
        except Exception as e:
            print(f"Error while connecting to PostgreSQL: {e}")
            return False

    def disconnect(self):
        """Closes the connection if it is open."""
        if self.connection and not self.connection.closed:
            self.connection.close()
            print("PostgreSQL connection is closed")

    def execute_query(self, query, params=None):
        """Executes a query and returns the results for SELECT queries."""
        if not self.connection or self.connection.closed:
             if not self.connect():
                 return None
        
        cursor = self.connection.cursor(cursor_factory=RealDictCursor)
        try:
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            if query.strip().upper().startswith(("SELECT", "SHOW")):
                result = cursor.fetchall()
                # Convert RealDictRow to regular dicts
                return [dict(row) for row in result]
            else:
                self.connection.commit()
                return cursor.rowcount
        except Exception as e:
            print(f"Error executing query: {e}")
            self.connection.rollback()
            return None
        finally:
            cursor.close()
