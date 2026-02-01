import os
import platform
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

# Global connection pool - created once, reused for all requests
_connection_pool = None

def get_connection_pool():
    """Get or create the global connection pool."""
    global _connection_pool
    if _connection_pool is None:
        # Determine host based on platform
        if platform.system() == "Windows":
            host = "hope.global.ba"
        else:
            host = "localhost"
        
        _connection_pool = pool.ThreadedConnectionPool(
            minconn=2,      # Minimum connections to keep open
            maxconn=10,     # Maximum connections allowed
            host=host,
            database="velorusb_echoHistory",
            user="velorusb_echoHistoryAdmin",
            password="Pijanista123!",
            port=5432
        )
        print("Database connection pool created")
    return _connection_pool

class Database:
    def __init__(self):
        self.connection = None
        self._from_pool = False

    def connect(self):
        """Get a connection from the pool."""
        try:
            pool = get_connection_pool()
            self.connection = pool.getconn()
            self._from_pool = True
            return True
        except Exception as e:
            print(f"Error getting connection from pool: {e}")
            return False

    def disconnect(self):
        """Return connection to the pool (don't actually close it)."""
        if self.connection and self._from_pool:
            try:
                pool = get_connection_pool()
                pool.putconn(self.connection)
            except Exception as e:
                print(f"Error returning connection to pool: {e}")
            self.connection = None

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
