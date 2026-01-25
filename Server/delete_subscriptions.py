from database import Database
import sys

def delete_all_subscriptions():
    print("Initializing Database...")
    try:
        db = Database()
        
        print("Executing DELETE FROM subscriptions...")
        deleted_count = db.execute_query("DELETE FROM subscriptions")
        
        if deleted_count is not None:
             print(f"SUCCESS: Deleted {deleted_count} rows from 'subscriptions' table.")
        else:
             print("ERROR: Failed to execute query.")
             
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    delete_all_subscriptions()
