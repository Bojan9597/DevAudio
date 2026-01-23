from database import Database

def init_db():
    db = Database()
    
    # Create user_downloads table
    # Using INT UNSIGNED to match referenced tables
    query = """
    CREATE TABLE IF NOT EXISTS user_downloads (
        user_id INT UNSIGNED,
        book_id INT UNSIGNED,
        downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, book_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
    )
    """
    result = db.execute_query(query)
    if result is not None:
        print("user_downloads table created successfully (or already exists)")
    else:
        print("Failed to create table")
    
    db.disconnect()

if __name__ == "__main__":
    init_db()
