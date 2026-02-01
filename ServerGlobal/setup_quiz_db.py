#!/usr/bin/env python3
"""Create the quizzes, quiz_questions, and user_quiz_results tables for PostgreSQL."""

from database import Database

def setup_quiz_tables():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    try:
        print("Creating Quiz tables...")
        
        # Quizzes Table
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS quizzes (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_quizzes_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                CONSTRAINT unique_book_quiz UNIQUE (book_id)
            )
        """)
        
        # Quiz Questions Table
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS quiz_questions (
                id SERIAL PRIMARY KEY,
                quiz_id INT NOT NULL,
                question_text TEXT NOT NULL,
                option_a VARCHAR(255) NOT NULL,
                option_b VARCHAR(255) NOT NULL,
                option_c VARCHAR(255) NOT NULL,
                option_d VARCHAR(255) NOT NULL,
                correct_answer CHAR(1) NOT NULL,
                order_index INT DEFAULT 0,
                CONSTRAINT fk_quiz_questions_quiz FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
            )
        """)

        # Quiz Results Table
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS user_quiz_results (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL,
                quiz_id INT NOT NULL,
                score_percentage DECIMAL(5,2) DEFAULT 0.00,
                is_passed BOOLEAN DEFAULT FALSE,
                completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_user_quiz_results_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                CONSTRAINT fk_user_quiz_results_quiz FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
            )
        """)
        
        print("Quiz tables and result tracking created.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    setup_quiz_tables()
