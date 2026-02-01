import psycopg2
from database import Database

def add_search_indexes():
    print("Connecting to database...")
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    commands = [
        # 1. Enable the pg_trgm extension (Required for fuzzy search indexing)
        "CREATE EXTENSION IF NOT EXISTS pg_trgm;",
        
        # 2. Add GIN Index on Title (Fast 'LIKE %query%' search)
        """
        CREATE INDEX IF NOT EXISTS idx_books_title_search 
        ON books USING GIN (title gin_trgm_ops);
        """,
        
        # 3. Add GIN Index on Author
        """
        CREATE INDEX IF NOT EXISTS idx_books_author_search 
        ON books USING GIN (author gin_trgm_ops);
        """
    ]

    try:
        cur = db.connection.cursor()
        for cmd in commands:
            print(f"Executing: {cmd.strip()}")
            cur.execute(cmd)
        
        db.connection.commit()
        print("✅ Successfully added SEARCH optimization indexes!")
        
    except Exception as e:
        print(f"❌ Error adding search indexes: {e}")
        db.connection.rollback()
    finally:
        db.disconnect()

if __name__ == "__main__":
    add_search_indexes()
