from database import Database

def setup_quiz_tables():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    try:
        print("Creating Quiz tables...")
        
        # Quizzes Table
        # One quiz per book for simplicity based on request "quiz next to the book"
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS quizzes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                book_id INT UNSIGNED NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                UNIQUE KEY unique_book_quiz (book_id)
            )
        """)
        
        # Quiz Questions Table
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS quiz_questions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                quiz_id INT NOT NULL,
                question_text TEXT NOT NULL,
                option_a VARCHAR(255) NOT NULL,
                option_b VARCHAR(255) NOT NULL,
                option_c VARCHAR(255) NOT NULL,
                option_d VARCHAR(255) NOT NULL,
                correct_answer CHAR(1) NOT NULL,
                order_index INT DEFAULT 0,
                FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
            )
        """)

        # Quiz Results Table
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS user_quiz_results (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT UNSIGNED NOT NULL,
                quiz_id INT NOT NULL,
                score_percentage DECIMAL(5,2) DEFAULT '0.00',
                is_passed BOOLEAN DEFAULT FALSE,
                completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
            )
        """)
        
        print("Quiz tables and result tracking created.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    setup_quiz_tables()
