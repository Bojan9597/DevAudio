from database import Database
import sys
from dotenv import load_dotenv
load_dotenv()


try:
    db = Database()
    if db.connect():
        print("Connected to database")
        res = db.execute_query("SELECT column_name FROM information_schema.columns WHERE table_name='users'")
        columns = [r['column_name'] for r in res]
        print("Columns in users table:", columns)
        
        if 'reels_offset' in columns:
            print("reels_offset column EXISTS")
        else:
            print("reels_offset column MISSING")
            
        db.disconnect()
    else:
        print("Failed to connect to database")
except Exception as e:
    print(f"Error: {e}")
