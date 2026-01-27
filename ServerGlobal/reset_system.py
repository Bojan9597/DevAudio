import os
import shutil
from database import Database

def reset_database():
    print("Connecting to database...")
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    cursor = db.connection.cursor()
    
    # Disable FK checks to allow truncation
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    
    # List of tables to truncate (clearing dynamic data)
    tables_to_clear = [
        "users", 
        "pending_users",
        "books", 
        "user_books",
        "playlist_items",
        "user_completed_tracks",
        "quizzes",
        "quiz_questions",
        "user_quiz_results",
        "user_badges",
        "book_categories",
        "playback_history"
    ]
    
    print("Checking existing tables...")
    cursor.execute("SHOW TABLES")
    existing_tables = [row[0] for row in cursor.fetchall()]
    
    for table in tables_to_clear:
        if table in existing_tables:
            print(f"Truncating table: {table}")
            cursor.execute(f"TRUNCATE TABLE {table}")
        else:
            print(f"Table {table} does not exist, skipping.")
        
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    db.connection.commit()
    db.disconnect()
    print("Database data cleared.")

def clear_directory(path):
    if os.path.exists(path):
        print(f"Clearing directory: {path}")
        for filename in os.listdir(path):
            file_path = os.path.join(path, filename)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)
                elif os.path.isdir(file_path):
                    shutil.rmtree(file_path)
            except Exception as e:
                print(f'Failed to delete {file_path}. Reason: {e}')
    else:
        print(f"Directory {path} not found.")

def reset_files():
    base_static = os.path.join(os.path.dirname(__file__), 'static')
    
    folders = ['profilePictures', 'AudioBooks', 'BookCovers']
    
    for folder in folders:
        full_path = os.path.join(base_static, folder)
        clear_directory(full_path)

if __name__ == "__main__":
    print("WARNING: This will delete ALL data (users, books, quizzes) and files.")
    confirm = input("Are you sure? (yes/no): ")
    if confirm.lower() == 'yes':
        reset_database()
        reset_files()
        print("System reset complete.")
    else:
        print("Operation cancelled.")
