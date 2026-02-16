from database import Database
from dotenv import load_dotenv
import os

# Load env variables
load_dotenv()

ADMIN_EMAIL = "bojanpejic97@gmail.com"

def cleanup_users():
    print("Starting User Cleanup...")
    
    db = Database()
    if not db.connect():
        print("❌ Database connection failed.")
        return

    try:
        # Check current user count
        count_query = "SELECT COUNT(*) as cnt FROM users"
        res = db.execute_query(count_query)
        initial_count = res[0]['cnt']
        print(f"Current user count: {initial_count}")

        # Delete non-admin users
        print(f"Deleting all users except: {ADMIN_EMAIL}")
        delete_query = "DELETE FROM users WHERE email != %s"
        db.execute_query(delete_query, (ADMIN_EMAIL,))
        
        # Check new user count
        res_after = db.execute_query(count_query)
        final_count = res_after[0]['cnt']
        deleted_count = initial_count - final_count
        
        print(f"✅ Cleanup completed. Deleted {deleted_count} users.")
        print(f"Remaining users: {final_count}")

    except Exception as e:
        print(f"❌ Cleanup failed: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    cleanup_users()
