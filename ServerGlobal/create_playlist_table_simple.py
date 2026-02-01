#!/usr/bin/env python3
"""Create a simplified playlist_items table for PostgreSQL (no foreign keys)."""

from database import Database

def create_playlist_items_table_simple():
    db = Database()
    if db.connect():
        try:
            # Drop if exists
            db.execute_query("DROP TABLE IF EXISTS playlist_items CASCADE")

            # Create table WITHOUT Foreign Key first
            query = """
            CREATE TABLE playlist_items (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL,
                file_path VARCHAR(512) NOT NULL,
                title VARCHAR(255) NOT NULL,
                duration_seconds INT DEFAULT 0,
                track_order INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
            print("Creating playlist_items table (Simplified)...")
            db.execute_query(query)
            print("Table created successfully.")
            
            # Add Index
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_playlist_items_book_id ON playlist_items(book_id)")

        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    create_playlist_items_table_simple()
