#!/usr/bin/env python3
"""Create the token_blacklist table for PostgreSQL."""

from database import Database

def table_exists(db, table):
    """Check if a table exists using PostgreSQL information_schema."""
    result = db.execute_query("""
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = %s
        )
    """, (table,))
    return result and result[0].get('exists', False)

def create_blacklist_table():
    print("Connecting to database...")
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    print("Creating token_blacklist table...")
    
    if not table_exists(db, 'token_blacklist'):
        create_query = """
        CREATE TABLE token_blacklist (
            id SERIAL PRIMARY KEY,
            token VARCHAR(512) NOT NULL,
            blacklisted_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL
        )
        """
        try:
            db.execute_query(create_query)
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_token_blacklist_token ON token_blacklist(token)")
            print("Successfully created 'token_blacklist' table.")
        except Exception as e:
            print(f"Error creating table: {e}")
    else:
        print("'token_blacklist' table already exists.")

    db.disconnect()

if __name__ == "__main__":
    create_blacklist_table()
