import psycopg2
from database import Database

def add_indexes():
    print("Connecting to database...")
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    commands = [
        # Optimize listen history query: ORDER BY last_accessed_at DESC
        """
        CREATE INDEX IF NOT EXISTS idx_user_books_history 
        ON user_books (user_id, last_accessed_at DESC);
        """,
        
        # Optimize sub-queries for avg rating (Covering index)
        """
        CREATE INDEX IF NOT EXISTS idx_book_ratings_stats 
        ON book_ratings (book_id, stars);
        """,
        
        # Optimize playlist item counting per book
        """
        CREATE INDEX IF NOT EXISTS idx_playlist_items_count 
        ON playlist_items (book_id);
        """
    ]

    try:
        cur = db.connection.cursor()
        for cmd in commands:
            print(f"Executing: {cmd.strip()}")
            cur.execute(cmd)
        
        db.connection.commit()
        print("✅ Successfully added performance indexes!")
        
    except Exception as e:
        print(f"❌ Error adding indexes: {e}")
        db.connection.rollback()
    finally:
        db.disconnect()

if __name__ == "__main__":
    add_indexes()
