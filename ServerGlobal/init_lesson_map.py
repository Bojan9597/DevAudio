#!/usr/bin/env python3
"""Create the user_completed_tracks table for PostgreSQL."""

from database import Database

def init_lesson_map_table():
    print("Initializing Lesson Map tables...")
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    try:
        query = """
        CREATE TABLE IF NOT EXISTS user_completed_tracks (
            id SERIAL PRIMARY KEY,
            user_id INT NOT NULL,
            track_id INT NOT NULL,
            completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT unique_completion UNIQUE (user_id, track_id),
            CONSTRAINT fk_user_completed_tracks_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_user_completed_tracks_track FOREIGN KEY (track_id) REFERENCES playlist_items(id) ON DELETE CASCADE
        )
        """
        db.execute_query(query)
        print("Table 'user_completed_tracks' created successfully.")
        
    except Exception as e:
        print(f"Error initializing tables: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    init_lesson_map_table()
