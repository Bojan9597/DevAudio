from database import Database

def fix_table():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        print("Truncating user_sessions...")
        cursor.execute("TRUNCATE TABLE user_sessions")
        
        print("Altering table to add UNIQUE constraint...")
        try:
            # Check if index exists first? Or just try adding it.
            cursor.execute("ALTER TABLE user_sessions ADD UNIQUE KEY unique_user (user_id)")
            print("Constraint added successfully.")
        except Exception as e:
            print(f"Error adding constraint (might already exist?): {e}")

        db.connection.commit()
        db.disconnect()
    else:
        print("Failed to connect")

if __name__ == "__main__":
    fix_table()
