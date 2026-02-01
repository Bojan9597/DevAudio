#!/usr/bin/env python3
"""Create the user_books table for PostgreSQL."""

from database import Database

def main():
    db = Database()
    if db.connect():
        print("Connected. Creating user_books table...")
        try:
            # Create user_books table
            query = """
            CREATE TABLE IF NOT EXISTS user_books (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL,
                book_id INT NOT NULL,
                purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_user_books_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                CONSTRAINT fk_user_books_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                CONSTRAINT unique_user_book UNIQUE (user_id, book_id)
            )
            """
            db.execute_query(query)
            print("Table 'user_books' created or already exists.")
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect.")

if __name__ == "__main__":
    main()
