#!/usr/bin/env python3
"""Create user_track_progress table for PostgreSQL."""

from database import Database

def column_exists(db, table, column):
    """Check if a column exists in a table using PostgreSQL information_schema."""
    result = db.execute_query("""
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = %s AND column_name = %s
        )
    """, (table, column))
    return result and result[0].get('exists', False)

def migrate():
    db = Database()
    if db.connect():
        print("Migrating database for track progress...")

        try:
            # 1. Create user_track_progress table
            print("Creating user_track_progress table...")
            db.execute_query("""
                CREATE TABLE IF NOT EXISTS user_track_progress (
                    id SERIAL PRIMARY KEY,
                    user_id INT NOT NULL,
                    book_id INT NOT NULL,
                    playlist_item_id INT NOT NULL,
                    position_seconds INT DEFAULT 0,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT fk_user_track_progress_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                    CONSTRAINT fk_user_track_progress_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                    CONSTRAINT fk_user_track_progress_item FOREIGN KEY (playlist_item_id) REFERENCES playlist_items(id) ON DELETE CASCADE,
                    CONSTRAINT unique_user_track UNIQUE (user_id, playlist_item_id)
                )
            """)
            
            # Create trigger for updated_at
            db.execute_query("""
                CREATE OR REPLACE FUNCTION update_user_track_progress_updated_at()
                RETURNS TRIGGER AS $$
                BEGIN
                    NEW.updated_at = CURRENT_TIMESTAMP;
                    RETURN NEW;
                END;
                $$ language 'plpgsql'
            """)
            db.execute_query("DROP TRIGGER IF EXISTS trg_user_track_progress_updated_at ON user_track_progress")
            db.execute_query("""
                CREATE TRIGGER trg_user_track_progress_updated_at
                    BEFORE UPDATE ON user_track_progress
                    FOR EACH ROW
                    EXECUTE FUNCTION update_user_track_progress_updated_at()
            """)

            # 2. Add current_playlist_item_id to user_books
            print("Checking user_books for current_playlist_item_id column...")
            
            if not column_exists(db, 'user_books', 'current_playlist_item_id'):
                print("Adding current_playlist_item_id to user_books...")
                db.execute_query("""
                    ALTER TABLE user_books
                    ADD COLUMN current_playlist_item_id INT DEFAULT NULL
                """)
            else:
                print("Column current_playlist_item_id already exists.")

            print("Migration successful.")

        except Exception as e:
            print(f"Error during migration: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect to database.")

if __name__ == "__main__":
    migrate()
