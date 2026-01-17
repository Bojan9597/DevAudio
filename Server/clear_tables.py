from database import Database

def clear_data():
    db = Database()
    if not db.connect():
        print("Failed to connect")
        return

    tables_to_clear = [
        'token_blacklist',
        'user_badges', # Assuming this links users to badges
        'user_completed_tracks',
        'user_track_progress',
        'user_quiz_results',
        'user_books',
        'favorites',
        'playback_history',
        'bookmarks',
        'pending_users',
        'quiz_questions',
        'quizzes',
        'playlist_items',
        'book_categories',
        'books',
        'users'
    ]

    print("Clearing tables...")
    cursor = db.connection.cursor()
    
    # Disable FK checks
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    
    for table in tables_to_clear:
        try:
            print(f"Clearing {table}...")
            cursor.execute(f"DELETE FROM {table}") # Use DELETE FROM to clear data, keep structure
            # Or TRUNCATE TABLE {table} - but DELETE is safer with FKs sometimes even with check disabled? 
            # TRUNCATE is faster and resets auto_increment. Let's use DELETE to be safe with partial restores if needed, but TRUNCATE is cleaner for "beginning". 
            # I will use DELETE.
        except Exception as e:
            # Table might not exist, just print and continue
            print(f"Skipping {table}: {e}")
            
    # Reset Auto Increment for users/books if possible?
    try:
        cursor.execute("ALTER TABLE users AUTO_INCREMENT = 1")
        cursor.execute("ALTER TABLE books AUTO_INCREMENT = 1")
    except:
        pass

    # Enable FK checks
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    db.connection.commit()
    cursor.close()
    db.disconnect()
    print("Database cleared (Users, Books, etc). Categories and Badges preserved.")

if __name__ == "__main__":
    clear_data()
