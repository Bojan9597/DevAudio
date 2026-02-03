import os
import time
import platform
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

# Global connection pool - created once, reused for all requests
_connection_pool = None

def get_connection_pool():
    """Get or create the global connection pool."""
    global _connection_pool
    if _connection_pool is None or _connection_pool.closed:
        # Determine host based on platform
        if platform.system() == "Windows":
            host = "hope.global.ba"
        else:
            host = "localhost"

        _connection_pool = pool.ThreadedConnectionPool(
            minconn=2,      # Minimum connections to keep open
            maxconn=20,     # Increased pool size - same server so no external limit
            host=host,
            database="velorusb_echoHistory",
            user="velorusb_echoHistoryAdmin",
            password="Pijanista123!",
            port=5432,
            connect_timeout=5,  # 5 second timeout for establishing connection
            options='-c statement_timeout=5000'  # 5 second query timeout (in ms)
        )
        print("Database connection pool created")
    return _connection_pool

class Database:
    def __init__(self):
        self.connection = None
        self._from_pool = False

    def __enter__(self):
        """Context manager entry - connects to database."""
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - always disconnects."""
        self.disconnect()
        return False  # Don't suppress exceptions

    def __del__(self):
        """Destructor - safety net to return connection if forgot to disconnect."""
        if self.connection and self._from_pool:
            try:
                self.disconnect()
            except Exception:
                pass

    def connect(self, retries=2, delay=0.1):
        """Get a connection from the pool with retry logic."""
        for attempt in range(retries):
            try:
                p = get_connection_pool()
                # Use blocking=False to fail immediately if pool exhausted
                # instead of waiting indefinitely
                self.connection = p.getconn()
                # Validate the connection is still alive
                if self.connection.closed:
                    p.putconn(self.connection, close=True)
                    self.connection = None
                    continue
                self._from_pool = True
                return True
            except pool.PoolError as e:
                # Pool exhausted - short wait and retry once
                print(f"Pool exhausted (attempt {attempt+1}/{retries}): {e}")
                if attempt < retries - 1:
                    time.sleep(delay)
            except Exception as e:
                print(f"Error getting connection from pool: {e}")
                return False
        print("Failed to get connection after all retries")
        return False

    def disconnect(self):
        """Return connection to the pool (don't actually close it)."""
        if self.connection and self._from_pool:
            try:
                # Reset connection state before returning to pool
                if not self.connection.closed:
                    self.connection.reset()
                p = get_connection_pool()
                p.putconn(self.connection)
            except Exception as e:
                print(f"Error returning connection to pool: {e}")
                # If we can't return it cleanly, close it so pool can create a fresh one
                try:
                    p = get_connection_pool()
                    p.putconn(self.connection, close=True)
                except Exception:
                    pass
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
