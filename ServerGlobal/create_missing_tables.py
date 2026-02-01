#!/usr/bin/env python3
"""Create the playback_history table for PostgreSQL."""

from database import Database

def create_tables():
    db = Database()
    if db.connect():
        
        print("Creating table playback_history if missing...")
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS playback_history (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL,
                book_id INT NOT NULL,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                played_seconds INT DEFAULT 0,
                CONSTRAINT fk_playback_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                CONSTRAINT fk_playback_history_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
            )
        """)
        
        db.disconnect()
        print("Table creation complete.")
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    create_tables()
