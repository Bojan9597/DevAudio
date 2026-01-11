import mysql.connector
import mysql.connector
import json

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Pijanista123!",
        database="audiobooks"
    )

def migrate_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # 1. Create badges table
        print("Creating 'badges' table...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS badges (
                id INT AUTO_INCREMENT PRIMARY KEY,
                category VARCHAR(50) NOT NULL,
                name VARCHAR(100) NOT NULL,
                description TEXT,
                code VARCHAR(50) UNIQUE NOT NULL,
                threshold INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 2. Create user_badges table
        print("Creating 'user_badges' table...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_badges (
                user_id INT UNSIGNED NOT NULL,
                badge_id INT NOT NULL,
                earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (user_id, badge_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
            )
        """)

        # 3. Alter user_books table to add started_at and completed_at
        print("Checking columns in 'user_books'...")
        cursor.execute("SHOW COLUMNS FROM user_books LIKE 'started_at'")
        if not cursor.fetchone():
            print("Adding 'started_at' to user_books...")
            cursor.execute("ALTER TABLE user_books ADD COLUMN started_at TIMESTAMP NULL DEFAULT NULL")
        
        cursor.execute("SHOW COLUMNS FROM user_books LIKE 'completed_at'")
        if not cursor.fetchone():
            print("Adding 'completed_at' to user_books...")
            cursor.execute("ALTER TABLE user_books ADD COLUMN completed_at TIMESTAMP NULL DEFAULT NULL")

        # 4. Insert Badge Definitions
        print("Inserting badge definitions...")
        badges = [
            # 1. Reading Frequency
            ('Frequency', 'First Steps', 'Listen to your first book.', 'freq_first_listen', 1),
            ('Frequency', 'Getting Started', 'Listen to 3 books in a week.', 'freq_3_week', 3),
            ('Frequency', 'Habit Builder', 'Listen to at least 1 book every day for 7 consecutive days.', 'freq_7_days', 7),
            ('Frequency', 'Consistency Champ', 'Listen to a book every day for 30 days.', 'freq_30_days', 30),

            # 2. Time Spent (Seconds)
            ('Time', 'Quick Listener', 'Spend a total of 500 seconds (≈8 minutes).', 'time_500s', 500),
            ('Time', 'Dedicated Listener', 'Spend a total of 5,000 seconds (≈1.4 hours).', 'time_5000s', 5000),
            ('Time', 'Marathon Listener', 'Spend 50,000 seconds (≈14 hours).', 'time_50000s', 50000),
            ('Time', 'Audio Addict', 'Spend 200,000 seconds (≈55 hours).', 'time_200000s', 200000),

            # 3. Books Completed
            ('Books', 'Bookworm', 'Finish your first book.', 'books_1', 1),
            ('Books', 'Collector', 'Finish 5 books.', 'books_5', 5),
            ('Books', 'Bibliophile', 'Finish 20 books.', 'books_20', 20),
            ('Books', 'Master Listener', 'Finish 50 books.', 'books_50', 50),

            # 4. Genre Diversity
            ('Genre', 'Explorer', 'Listen to books from 3 different genres.', 'genre_3', 3),
            ('Genre', 'Adventurer', 'Listen to books from 5 different genres.', 'genre_5', 5),
            ('Genre', 'Omnireader', 'Listen to books from 10 different genres.', 'genre_10', 10),

            # 5. Speed / Efficiency (Logic handled in code)
            ('Speed', 'Fast Track', 'Finish a book in less than 2 days.', 'speed_2_days', 0),
            ('Speed', 'Speed Reader', 'Finish 3 books in a week.', 'speed_3_week', 0),
            ('Speed', 'Record Breaker', 'Finish a book in under 4 hours.', 'speed_4_hours', 0),

            # 6. Social (Placeholder logic for now)
            ('Social', 'Social Listener', 'Share your first book recommendation.', 'social_share_1', 1),
            ('Social', 'Book Clubber', 'Recommend 5 books.', 'social_share_5', 5),
            ('Social', 'Influencer', 'Recommend 20 books.', 'social_share_20', 20),

            # 7. Milestones
            ('Milestone', 'Night Owl', 'Listen between 12 AM – 4 AM.', 'mile_night_owl', 0),
            ('Milestone', 'Early Bird', 'Listen between 4 AM – 8 AM.', 'mile_early_bird', 0),
            ('Milestone', 'Weekend Warrior', 'Finish a book entirely during the weekend.', 'mile_weekend', 0),
            ('Milestone', 'Holiday Listener', 'Listen for a total of 5 hours during a holiday week.', 'mile_holiday', 0),
        ]

        for b in badges:
            try:
                cursor.execute("""
                    INSERT INTO badges (category, name, description, code, threshold) 
                    VALUES (%s, %s, %s, %s, %s)
                """, b)
            except mysql.connector.errors.IntegrityError:
                pass # Already exists

        conn.commit()
        print("Migration successful!")

    except Exception as e:
        print(f"Error during migration: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    migrate_db()
