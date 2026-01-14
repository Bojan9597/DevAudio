import mysql.connector
from database import Database

def create_tables():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        
        print("Creating table playback_history if missing...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS playback_history (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT UNSIGNED NOT NULL,
                book_id INT UNSIGNED NOT NULL,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                played_seconds INT DEFAULT 0,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
            )
        """)
        
        db.disconnect()
        print("Table creation complete.")
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    create_tables()
