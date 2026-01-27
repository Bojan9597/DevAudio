import mysql.connector
from database import Database

def undo_rename():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        
        # Renames to perform (New -> Old)
        renames = [
            ("book_quizzes", "quizzes"),
            ("book_quiz_questions", "quiz_questions"),
            ("user_book_quiz_results", "user_quiz_results")
        ]
        
        for new_name, old_name in renames:
            try:
                # Check if new table exists
                cursor.execute(f"SHOW TABLES LIKE '{new_name}'")
                if cursor.fetchone():
                    # Check if old table already exists (safety)
                    cursor.execute(f"SHOW TABLES LIKE '{old_name}'")
                    if cursor.fetchone():
                        print(f"Skipping {new_name} -> {old_name}: Target already exists.")
                    else:
                        print(f"Renaming {new_name} to {old_name}...")
                        cursor.execute(f"RENAME TABLE {new_name} TO {old_name}")
                else:
                    print(f"Skipping {new_name}: Table not found.")
            except Exception as e:
                print(f"Error renaming {new_name}: {e}")
                
        db.disconnect()
        print("Database revert complete.")
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    undo_rename()
