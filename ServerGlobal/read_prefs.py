from database import Database
from dotenv import load_dotenv
import os
import json

# Load env variables
load_dotenv()

USER_EMAIL = "bojanpejic97@gmail.com"

def read_prefs():
    print(f"Reading prefs for: {USER_EMAIL}")
    
    db = Database()
    if not db.connect():
        print("❌ Database connection failed.")
        return

    try:
        query = "SELECT id, email, current_streak, last_daily_goal_at, preferences FROM users WHERE email = %s"
        res = db.execute_query(query, (USER_EMAIL,))
        
        if res:
            user = res[0]
            print("\n--- User Data ---")
            print(f"ID: {user['id']}")
            print(f"Email: {user['email']}")
            print(f"Current Streak: {user['current_streak']}")
            print(f"Last Goal At: {user['last_daily_goal_at']}")
            print(f"Preferences (Raw): {user['preferences']}")
            
            if user['preferences']:
                try:
                    prefs = user['preferences']
                    if isinstance(prefs, str):
                        prefs = json.loads(prefs)
                    print(f"Preferences (Parsed): {json.dumps(prefs, indent=2)}")
                except Exception as e:
                    print(f"Error parsing prefs: {e}")
        else:
            print("❌ User not found.")

    except Exception as e:
        print(f"❌ Read failed: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    read_prefs()
