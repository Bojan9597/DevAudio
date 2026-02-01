#!/usr/bin/env python3
"""Create the quizzes table for PostgreSQL."""

from database import Database

def migrate():
    db = Database()
    if db.connect():
        try:
            print("Creating quizzes table...")
            query = """
            CREATE TABLE IF NOT EXISTS quizzes (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL,
                track_id INT NOT NULL,
                question TEXT NOT NULL,
                option_a VARCHAR(255) NOT NULL,
                option_b VARCHAR(255) NOT NULL,
                option_c VARCHAR(255) NOT NULL,
                option_d VARCHAR(255) NOT NULL,
                correct_answer CHAR(1) NOT NULL, -- 'A', 'B', 'C', 'D'
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_quizzes_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                CONSTRAINT fk_quizzes_track FOREIGN KEY (track_id) REFERENCES playlist_items(id) ON DELETE CASCADE,
                CONSTRAINT unique_track_quiz UNIQUE (track_id)
            )
            """
            db.execute_query(query)
            print("Quizzes table created successfully.")
            
        except Exception as e:
            print(f"Error migrating: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    migrate()
