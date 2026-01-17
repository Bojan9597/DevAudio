from database import Database

def add_session_id():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        print("Checking for session_id column...")
        try:
            cursor.execute("DESCRIBE user_sessions")
            columns = [row[0] for row in cursor.fetchall()]
            if 'session_id' in columns:
                print("Column 'session_id' already exists.")
            else:
                print("Adding 'session_id' column...")
                cursor.execute("ALTER TABLE user_sessions ADD COLUMN session_id VARCHAR(255) AFTER user_id")
                print("Column added.")
                
                # Make it unique? Yes, technically.
                # cursor.execute("ALTER TABLE user_sessions ADD UNIQUE KEY unique_session (session_id)")
        except Exception as e:
            print(f"Error checking/altering table: {e}")

        # Clear table to avoid null session_ids causing issues
        print("Truncating table to ensure clean state...")
        cursor.execute("TRUNCATE TABLE user_sessions")
        
        db.connection.commit()
        db.disconnect()

if __name__ == "__main__":
    add_session_id()
