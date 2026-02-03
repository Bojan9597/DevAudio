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
        """,

        # Optimize favorites lookup by user
        """
        CREATE INDEX IF NOT EXISTS idx_favorites_user
        ON favorites (user_id, book_id);
        """,

        # Optimize playback_history lookup for progress queries
        """
        CREATE INDEX IF NOT EXISTS idx_playback_history_user_book
        ON playback_history (user_id, book_id, played_seconds);
        """,

        # Optimize user_books lookup for is_read status
        """
        CREATE INDEX IF NOT EXISTS idx_user_books_user_book
        ON user_books (user_id, book_id, is_read);
        """,

        # Optimize books lookup by posted_by_user_id (uploaded books)
        """
        CREATE INDEX IF NOT EXISTS idx_books_posted_by
        ON books (posted_by_user_id);
        """,

        # Optimize subscription status check
        """
        CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status
        ON subscriptions (user_id, status, end_date);
        """,

        # Optimize user_completed_tracks lookup
        """
        CREATE INDEX IF NOT EXISTS idx_completed_tracks_user
        ON user_completed_tracks (user_id, track_id);
        """,

        # Optimize user_track_progress lookup
        """
        CREATE INDEX IF NOT EXISTS idx_track_progress_user_book
        ON user_track_progress (user_id, book_id, playlist_item_id);
        """,
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
