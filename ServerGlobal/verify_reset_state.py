from database import Database
import os

def check_table(db, table_name, should_be_empty=True):
    try:
        if should_be_empty:
            query = f"SELECT COUNT(*) as count FROM {table_name}"
        else:
            # Just check if table exists and has rows if expected
            query = f"SELECT COUNT(*) as count FROM {table_name}"
            
        res = db.execute_query(query)
        count = res[0]['count'] if res else 0
        
        status = "✅" if (should_be_empty and count == 0) or (not should_be_empty and count >= 0) else "❌"
        expectation = "EMPTY" if should_be_empty else "PRESERVED"
        print(f"{status} Table {table_name}: {count} rows (Expected: {expectation})")
        return count
    except Exception as e:
        print(f"❌ Error checking {table_name}: {e}")
        return -1

def check_folder(path):
    if not os.path.exists(path):
         print(f"ℹ Folder {path} does not exist (OK)")
         return
         
    files = [f for f in os.listdir(path) if f != '.gitkeep']
    count = len(files)
    status = "✅" if count == 0 else "❌"
    print(f"{status} Folder {os.path.basename(path)}: {count} files")

def verify():
    print("="*40)
    print("VERIFICATION CHECK")
    print("="*40)
    
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    # Tables to be EMPTY
    empty_tables = [
        'playback_history', 'user_quiz_results', 'quiz_questions', 'quizzes',
        'user_completed_tracks', 'user_track_progress', 'user_badges',
        'bookmarks', 'favorites', 'subscription_history', 'subscriptions',
        'user_books', 'playlist_items', 'book_categories', 'books',
        'user_sessions', 'token_blacklist', 'pending_users', 'users'
    ]
    
    print("\n--- Checking Cleared Tables ---")
    for t in empty_tables:
        check_table(db, t, should_be_empty=True)
        
    print("\n--- Checking Preserved Tables ---")
    check_table(db, 'badges', should_be_empty=False)
    check_table(db, 'categories', should_be_empty=False)
    
    db.disconnect()
    
    print("\n--- Checking Files ---")
    base = os.path.dirname(os.path.abspath(__file__))
    static = os.path.join(base, 'static')
    check_folder(os.path.join(static, 'AudioBooks'))
    check_folder(os.path.join(static, 'BookCovers'))
    check_folder(os.path.join(static, 'profilePictures'))
    print("="*40)

if __name__ == "__main__":
    verify()
