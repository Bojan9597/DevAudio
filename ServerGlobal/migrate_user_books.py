from database import Database

def main():
    db = Database()
    if db.connect():
        print("Connected. Creating user_books table...")
        try:
            # Create user_books table
            query = """
            CREATE TABLE IF NOT EXISTS user_books (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                user_id INT UNSIGNED NOT NULL,
                book_id INT UNSIGNED NOT NULL,
                purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                UNIQUE KEY unique_user_book (user_id, book_id)
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
