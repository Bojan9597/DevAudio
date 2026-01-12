from database import Database

def create_playlist_items_table_simple():
    db = Database()
    if db.connect():
        try:
            # 1. Check if books.id is unsigned
            # Actually, let's just create the table without FK first to be safe
            
            # Drop if exists
            db.execute_query("DROP TABLE IF EXISTS playlist_items")

            # Create table WITHOUT Foreign Key first
            # We will use INT for book_id. If books.id is BIGINT, this might be okay for storage but FK would fail.
            query = """
            CREATE TABLE playlist_items (
                id INT AUTO_INCREMENT PRIMARY KEY,
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
            
            # Optional: Add Index
            db.execute_query("CREATE INDEX idx_book_id ON playlist_items(book_id)")

        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    create_playlist_items_table_simple()
