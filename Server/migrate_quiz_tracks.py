from database import Database

def migrate_quiz_tracks():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    try:
        print("Migrating quizzes table for track support...")
        
        # 1. Add playlist_item_id column
        try:
            db.execute_query("ALTER TABLE quizzes ADD COLUMN playlist_item_id INT DEFAULT NULL AFTER book_id")
            print("Added playlist_item_id column.")
        except Exception as e:
            if "Duplicate column" in str(e):
                print("Column playlist_item_id already exists.")
            else:
                print(f"Error adding column: {e}")

        # 2. Add Foreign Key
        try:
            # Check if constraint exists? MySQL doesn't have IF NOT EXISTS for FK easily.
            # Just try adding it
            db.execute_query("""
                ALTER TABLE quizzes 
                ADD CONSTRAINT fk_quizzes_playlist_item 
                FOREIGN KEY (playlist_item_id) REFERENCES playlist_items(id) ON DELETE CASCADE
            """)
            print("Added FK constraint.")
        except Exception as e:
             print(f"FK creation error (might exist): {e}")

        # 3. Drop old unique constraint on book_id (unique_book_quiz)
        try:
            db.execute_query("ALTER TABLE quizzes DROP INDEX unique_book_quiz")
            print("Dropped old unique constraint unique_book_quiz.")
        except Exception as e:
            print(f"Error dropping index (might not exist): {e}")

        # 4. Add new unique constraint (book_id, playlist_item_id)
        # Note: MySQL treats NULL != NULL for unique. 
        # So multiple rows with same book_id and NULL playlist_item_id (book quiz) might be allowed?
        # Yes. We want only ONE book quiz per book.
        # So we might need a workaround or just enforce in code.
        # But for tracks: (book_id, playlist_item_id) should be unique.
        
        try:
            db.execute_query("CREATE UNIQUE INDEX unique_book_track_quiz ON quizzes (book_id, playlist_item_id)")
            print("Created new unique index unique_book_track_quiz.")
        except Exception as e:
            print(f"Index creation error: {e}")
            
        print("Migration complete.")
        
    except Exception as e:
        print(f"Global Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate_quiz_tracks()
