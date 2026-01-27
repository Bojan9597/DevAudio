#!/usr/bin/env python3
"""Create the book_ratings table for the rating feature."""

from database import Database

def create_book_ratings_table():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return
    
    try:
        create_table_query = """
            CREATE TABLE IF NOT EXISTS book_ratings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                book_id INT NOT NULL,
                user_id INT NOT NULL,
                stars INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY unique_user_book (user_id, book_id),
                INDEX idx_book_id (book_id),
                INDEX idx_user_id (user_id)
            )
        """
        cursor = db.connection.cursor()
        cursor.execute(create_table_query)
        db.connection.commit()
        cursor.close()
        print("✓ book_ratings table created successfully!")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    create_book_ratings_table()
