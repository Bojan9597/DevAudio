#!/usr/bin/env python3
"""Create the book_ratings table for the rating feature (PostgreSQL)."""

from database import Database

def create_book_ratings_table():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return
    
    try:
        # Create the table
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS book_ratings (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL,
                user_id INT NOT NULL,
                stars INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT unique_user_book UNIQUE (user_id, book_id)
            )
        """)

        # Create indices
        db.execute_query("CREATE INDEX IF NOT EXISTS idx_book_ratings_book_id ON book_ratings(book_id)")
        db.execute_query("CREATE INDEX IF NOT EXISTS idx_book_ratings_user_id ON book_ratings(user_id)")
        
        # Create trigger function for updated_at
        db.execute_query("""
            CREATE OR REPLACE FUNCTION update_updated_at_column()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$ language 'plpgsql'
        """)

        # Create trigger
        db.execute_query("DROP TRIGGER IF EXISTS update_book_ratings_updated_at ON book_ratings")
        db.execute_query("""
            CREATE TRIGGER update_book_ratings_updated_at
                BEFORE UPDATE ON book_ratings
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at_column()
        """)

        print("✓ book_ratings table created successfully!")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    create_book_ratings_table()
