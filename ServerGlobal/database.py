import os
import time
import platform
import threading
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

# Global connection pool - created once, reused for all requests
_connection_pool = None

# Track active connections with timestamps for auto-cleanup
_active_connections = {}  # connection_id -> (connection, acquire_time)
_connections_lock = threading.Lock()
MAX_CONNECTION_AGE_SECONDS = 3  # Auto-release connections older than 3 seconds

def get_connection_pool():
    """Get or create the global connection pool."""
    global _connection_pool
    if _connection_pool is None or _connection_pool.closed:
        # Determine host and port based on platform
        # Windows: direct to PG (dev), Linux: through PgBouncer (prod)
        if platform.system() == "Windows":
            host = "hope.global.ba"
            port = 5432
            options = '-c statement_timeout=3000'
        else:
            host = "localhost"
            port = 6432  # PgBouncer
            options = ''  # PgBouncer handles timeouts (query_timeout=3)

        _connection_pool = pool.ThreadedConnectionPool(
            minconn=5,      # Minimum connections to keep open
            maxconn=40,     # PgBouncer limits real PG connections to 80, app pool can be larger
            host=os.getenv("DB_HOST", host),
            database=os.getenv("DB_NAME", "velorusb_echoHistory"),
            user=os.getenv("DB_USER", "velorusb_echoHistoryAdmin"),
            password=os.getenv("DB_PASSWORD", "Pijanista123!"),
            port=int(os.getenv("DB_PORT", port)),
            connect_timeout=3,
            options=options
        )
        print(f"Database connection pool created (maxconn=40, port={port})")
    return _connection_pool


def cleanup_stale_connections():
    """Force-return any connections that have been held for too long."""
    global _active_connections
    now = time.time()
    stale = []
    
    with _connections_lock:
        for conn_id, (conn, acquire_time) in list(_active_connections.items()):
            age = now - acquire_time
            if age > MAX_CONNECTION_AGE_SECONDS:
                print(f"WARNING: Force-releasing stale connection (held for {age:.1f}s)")
                stale.append(conn_id)
                try:
                    p = get_connection_pool()
                    if not conn.closed:
                        conn.rollback()
                    p.putconn(conn)
                except Exception as e:
                    print(f"Error force-releasing connection: {e}")
                    try:
                        p.putconn(conn, close=True)
                    except:
                        pass
        
        for conn_id in stale:
            del _active_connections[conn_id]
    
    return len(stale)


class Database:
    def __init__(self):
        self.connection = None
        self._from_pool = False
        self._conn_id = None
        self._acquire_time = None

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
        # First, try to cleanup any stale connections
        cleanup_stale_connections()
        
        for attempt in range(retries):
            try:
                p = get_connection_pool()
                self.connection = p.getconn()
                # Validate the connection is still alive
                if self.connection.closed:
                    p.putconn(self.connection, close=True)
                    self.connection = None
                    continue
                self._from_pool = True
                self._acquire_time = time.time()
                self._conn_id = id(self.connection)
                
                # Track this connection
                with _connections_lock:
                    _active_connections[self._conn_id] = (self.connection, self._acquire_time)
                
                return True
            except pool.PoolError as e:
                # Pool exhausted - try cleanup and retry
                print(f"Pool exhausted (attempt {attempt+1}/{retries}): {e}")
                cleaned = cleanup_stale_connections()
                if cleaned > 0:
                    print(f"Cleaned up {cleaned} stale connection(s), retrying...")
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
            # Remove from tracking
            if self._conn_id:
                with _connections_lock:
                    _active_connections.pop(self._conn_id, None)
            
            try:
                # Rollback any uncommitted state before returning to pool
                # (rollback instead of reset for PgBouncer transaction pooling compatibility)
                if not self.connection.closed:
                    self.connection.rollback()
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
            self._conn_id = None

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
