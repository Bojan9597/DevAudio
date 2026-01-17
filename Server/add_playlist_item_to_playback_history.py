from database import Database

def add_playlist_item_column():
    """
    Add playlist_item_id column to playback_history table to track playback per track.
    This allows us to calculate total listen time by summing the last position of each track.
    """
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor()
        
        # Check if column already exists
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM information_schema.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'playback_history' 
            AND COLUMN_NAME = 'playlist_item_id'
        """)
        result = cursor.fetchone()
        
        if result[0] > 0:
            print("Column 'playlist_item_id' already exists in playback_history table")
            cursor.close()
            db.disconnect()
            return True
        
        print("Adding playlist_item_id column to playback_history table...")
        
        # Add the column
        cursor.execute("""
            ALTER TABLE playback_history 
            ADD COLUMN playlist_item_id INT NULL AFTER book_id
        """)
        
        print("Adding index on playlist_item_id...")
        cursor.execute("""
            CREATE INDEX idx_playlist_item_id ON playback_history(playlist_item_id)
        """)
        
        print("Adding foreign key constraint...")
        cursor.execute("""
            ALTER TABLE playback_history
            ADD CONSTRAINT fk_playback_playlist_item
            FOREIGN KEY (playlist_item_id) REFERENCES playlist_items(id) ON DELETE CASCADE
        """)
        
        db.connection.commit()
        cursor.close()
        
        print("✓ Migration completed successfully!")
        print("  - Added playlist_item_id column")
        print("  - Created index for better query performance")
        print("  - Added foreign key constraint to playlist_items")
        
        return True
        
    except Exception as e:
        print(f"Error during migration: {e}")
        db.connection.rollback()
        return False
    finally:
        db.disconnect()

if __name__ == "__main__":
    add_playlist_item_column()
