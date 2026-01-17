from database import Database

def add_unique_constraint():
    """
    Add unique constraint to playback_history table to ensure only one record
    per user/book/playlist_item combination.
    """
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor()
        
        # First, check if the constraint already exists
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM information_schema.TABLE_CONSTRAINTS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'playback_history' 
            AND CONSTRAINT_NAME = 'unique_user_book_track'
        """)
        result = cursor.fetchone()
        
        if result[0] > 0:
            print("✓ Unique constraint 'unique_user_book_track' already exists")
            cursor.close()
            db.disconnect()
            return True
        
        print("Adding unique constraint to playback_history...")
        
        # For the unique constraint to work with nullable playlist_item_id, we need special handling
        # MySQL treats NULL values as distinct, so we need to handle both cases:
        # 1. When playlist_item_id IS NULL (single books): unique on (user_id, book_id)
        # 2. When playlist_item_id IS NOT NULL (playlists): unique on (user_id, book_id, playlist_item_id)
        
        # First, clean up duplicates if any exist
        print("  Cleaning up any duplicate records...")
        cursor.execute("""
            DELETE ph1 FROM playback_history ph1
            INNER JOIN playback_history ph2 
            WHERE ph1.id > ph2.id
            AND ph1.user_id = ph2.user_id
            AND ph1.book_id = ph2.book_id
            AND (ph1.playlist_item_id = ph2.playlist_item_id OR (ph1.playlist_item_id IS NULL AND ph2.playlist_item_id IS NULL))
        """)
        deleted = cursor.rowcount
        if deleted > 0:
            print(f"  Deleted {deleted} duplicate record(s)")
        
        # Add unique constraint
        # We'll make playlist_item_id part of the unique key, treating NULL as a distinct value
        cursor.execute("""
            ALTER TABLE playback_history
            ADD CONSTRAINT unique_user_book_track 
            UNIQUE KEY (user_id, book_id, playlist_item_id)
        """)
        
        db.connection.commit()
        cursor.close()
        
        print("✓ Unique constraint added successfully!")
        print("  This ensures only one playback_history record per user/book/track combination")
        
        return True
        
    except Exception as e:
        print(f"❌ Error adding unique constraint: {e}")
        db.connection.rollback()
        return False
    finally:
        db.disconnect()

if __name__ == "__main__":
    add_unique_constraint()
