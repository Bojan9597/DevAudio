from database import Database

def migrate():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    try:
        # Check verification_code
        columns = db.execute_query("SHOW COLUMNS FROM users LIKE 'verification_code'")
        if columns:
            print("Column verification_code already exists.")
        else:
            print("Adding verification_code column...")
            db.execute_query("ALTER TABLE users ADD COLUMN verification_code VARCHAR(6) DEFAULT NULL")
            print("Column added successfully.")

        # Check is_verified
        columns = db.execute_query("SHOW COLUMNS FROM users LIKE 'is_verified'")
        if columns:
            print("Column is_verified already exists.")
        else:
            print("Adding is_verified column...")
            db.execute_query("ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE")
            # Mark existing users as verified so they don't get locked out
            db.execute_query("UPDATE users SET is_verified = TRUE WHERE is_verified IS FALSE") 
            print("Column added and existing users verified.")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate()
