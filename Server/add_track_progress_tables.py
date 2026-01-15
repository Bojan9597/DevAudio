import mysql.connector
from database import Database

def migrate():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        print("Migrating database for track progress...")

        try:
            # 1. Create user_track_progress table
            print("Creating user_track_progress table...")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_track_progress (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT UNSIGNED NOT NULL,
                    book_id INT UNSIGNED NOT NULL,
                    playlist_item_id INT NOT NULL,
                    position_seconds INT DEFAULT 0,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                    FOREIGN KEY (playlist_item_id) REFERENCES playlist_items(id) ON DELETE CASCADE,
                    UNIQUE KEY unique_user_track (user_id, playlist_item_id)
                )
            """)

            # 2. Add current_playlist_item_id to user_books
            print("Checking user_books for current_playlist_item_id column...")
            cursor.execute("DESCRIBE user_books")
            columns = [column[0] for column in cursor.fetchall()]
            
            if 'current_playlist_item_id' not in columns:
                print("Adding current_playlist_item_id to user_books...")
                # We can't strictly enforce FK here easily if it's nullable or if order matters, 
                # but let's try to make it an INT first.
                cursor.execute("""
                    ALTER TABLE user_books
                    ADD COLUMN current_playlist_item_id INT DEFAULT NULL
                """)
                # Optionally add FK constraint if desired, but might be complex if not careful.
                # Let's keep it simple for now, just an ID reference.
            else:
                print("Column current_playlist_item_id already exists.")

            db.connection.commit()
            print("Migration successful.")

        except Exception as e:
            print(f"Error during migration: {e}")
            db.connection.rollback()
        finally:
            cursor.close()
            db.disconnect()
    else:
        print("Failed to connect to database.")

if __name__ == "__main__":
    migrate()
