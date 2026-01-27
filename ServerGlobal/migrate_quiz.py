
from database import Database

def migrate():
    db = Database()
    if db.connect():
        try:
            print("Creating quizzes table...")
            query = """
            CREATE TABLE IF NOT EXISTS quizzes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                book_id INT NOT NULL,
                track_id INT NOT NULL,
                question TEXT NOT NULL,
                option_a VARCHAR(255) NOT NULL,
                option_b VARCHAR(255) NOT NULL,
                option_c VARCHAR(255) NOT NULL,
                option_d VARCHAR(255) NOT NULL,
                correct_answer CHAR(1) NOT NULL, -- 'A', 'B', 'C', 'D'
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                FOREIGN KEY (track_id) REFERENCES playlist_items(id) ON DELETE CASCADE,
                UNIQUE KEY unique_track_quiz (track_id)
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
