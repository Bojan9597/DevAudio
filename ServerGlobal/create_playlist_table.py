#!/usr/bin/env python3
"""Create the playlist_items table for PostgreSQL."""

from database import Database

def create_playlist_items_table():
    db = Database()
    if db.connect():
        try:
            # Create table
            query = """
            CREATE TABLE IF NOT EXISTS playlist_items (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL,
                file_path VARCHAR(512) NOT NULL,
                title VARCHAR(255) NOT NULL,
                duration_seconds INT DEFAULT 0,
                track_order INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_playlist_items_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
            )
            """
            print("Creating playlist_items table...")
            db.execute_query(query)
            print("Table created successfully.")
            
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    create_playlist_items_table()
