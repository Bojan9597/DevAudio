from database import Database

def reset_progress():
    db = Database()
    if db.connect():
        try:
            cursor = db.connection.cursor()
            
            print("Resetting user progress...")
            
            # 1. Clear Quiz Results
            print("Clearing user_book_quiz_results...")
            cursor.execute("TRUNCATE TABLE user_book_quiz_results")
            
            # 2. Clear Track Completion
            print("Clearing user_completed_tracks...")
            cursor.execute("TRUNCATE TABLE user_completed_tracks")
            
            # 3. Reset Book Progress (keep the books in library, just reset stats)
            print("Resetting metadata in user_books...")
            cursor.execute("""
                UPDATE user_books 
                SET is_read = 0, 
                    last_played_position_seconds = 0, 
                    last_accessed_at = CURRENT_TIMESTAMP
            """)
            
            # 4. Remove Badges (Optional, but likely desired for "fresh run")
            print("Clearing user_badges...")
            cursor.execute("TRUNCATE TABLE user_badges")

            db.connection.commit()
            print("Progress reset successfully.")
            
        except Exception as e:
            print(f"Error resetting progress: {e}")
        finally:
            if cursor:
                cursor.close()
            db.disconnect()

if __name__ == "__main__":
    confirm = input("Are you sure you want to reset ALL user progress? (yes/no): ")
    if confirm.lower() == 'yes':
        reset_progress()
    else:
        print("Cancelled.")
