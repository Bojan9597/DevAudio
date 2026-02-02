
from database import Database
from dotenv import load_dotenv
import os

load_dotenv()

def migrate():
    try:
        db = Database()
        if not db.connect():
            print("Failed to connect to database using Database class.")
            return

        print("Connected to database.")
        
        # Check if column exists
        check_query = """
            SELECT count(*) 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name = 'reels_offset' 
            AND table_schema = DATABASE()
        """
        result = db.execute_query(check_query)
        exists = result[0]['count(*)'] if result else 0
        
        # Note: execute_query might return list of dicts. fetchone is handled inside?
        # Let's check api.py usage. It returns list of dicts usually.
        # But 'count(*)' might be the key.
        
        if not exists:
            print("Adding reels_offset column...")
            alter_query = "ALTER TABLE users ADD COLUMN reels_offset INT DEFAULT 0"
            db.execute_query(alter_query)
            print("Migration successful (or query executed).")
        else:
            print("Column reels_offset already exists.")
            
        db.disconnect()
        
    except Exception as e:
        print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
