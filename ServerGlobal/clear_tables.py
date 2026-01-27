from database import Database

def clear_data():
    db = Database()
    if not db.connect():
        print("Failed to connect")
        return

    tables_to_clear = [
        'user_sessions', # NEW
        'token_blacklist',
        'user_badges', 
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
        'book_categories', # Wait, this clears links. 
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
            cursor.execute(f"DELETE FROM {table}") 
        except Exception as e:
            print(f"Skipping {table}: {e}")
            
    # Reset Auto Increment
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
    
    # Clear Files
    import os
    import shutil
    
    folders_to_clear = [
        'static/AudioBooks',
        'static/BookCovers',
        'static/profilePictures'
    ]
    
    print("Clearing local files...")
    basedir = os.path.dirname(os.path.abspath(__file__))
    
    for folder in folders_to_clear:
        folder_path = os.path.join(basedir, folder)
        if os.path.exists(folder_path):
            print(f"Cleaning {folder}...")
            # Delete all files in folder but keep the folder itself
            for filename in os.listdir(folder_path):
                file_path = os.path.join(folder_path, filename)
                try:
                    if os.path.isfile(file_path) or os.path.islink(file_path):
                        os.unlink(file_path)
                    elif os.path.isdir(file_path):
                        shutil.rmtree(file_path)
                except Exception as e:
                    print(f"Failed to delete {file_path}. Reason: {e}")
        else:
            # Create if not exists code would go here, but we are clearing.
            pass

    print("System Cleaned (DB truncated + Files removed).")

if __name__ == "__main__":
    clear_data()
