from database import Database
from dotenv import load_dotenv
import os

# Load env variables
load_dotenv()

USER_EMAIL = "bojanpejic97@gmail.com"

def reset_prefs():
    print(f"Resetting prefs for: {USER_EMAIL}")
    
    db = Database()
    if not db.connect():
        print("❌ Database connection failed.")
        return

    try:
        query = "UPDATE users SET preferences = NULL WHERE email = %s"
        db.execute_query(query, (USER_EMAIL,))
        print("✅ Preferences set to NULL.")

    except Exception as e:
        print(f"❌ Reset failed: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    reset_prefs()
