from database import Database
from dotenv import load_dotenv
import json

load_dotenv()

def check_prefs():
    db = Database()
    if db.connect():
        try:
            # Check admin (ID 45 or email)
            # ADMIN_EMAIL = "bojanpejic97@gmail.com"
            cursor = db.connection.cursor()
            
            print("--- Fetching User Preferences ---")
            cursor.execute("SELECT id, email, preferences FROM users")
            users = cursor.fetchall()
            
            for u in users:
                print(f"User ID: {u[0]}")
                print(f"Email: {u[1]}")
                print(f"Preferences Raw: {u[2]}")
                print(f"Type: {type(u[2])}")
                print("-" * 30)
                
        finally:
            db.disconnect()
    else:
        print("DB Connection Failed")

if __name__ == "__main__":
    check_prefs()
