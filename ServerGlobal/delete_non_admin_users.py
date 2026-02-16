from database import Database
import sys
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


ADMIN_EMAIL = "bojanpejic97@gmail.com"

def delete_non_admin_users():
    print(f"Connecting to database to delete all users EXCEPT '{ADMIN_EMAIL}'...")
    db = Database()
    if db.connect():
        try:
            # First, check if admin exists
            cursor = db.connection.cursor()
            cursor.execute("SELECT id, name FROM users WHERE email = %s", (ADMIN_EMAIL,))
            admin = cursor.fetchone()
            
            if not admin:
                print(f"WARNING: Admin user '{ADMIN_EMAIL}' not found in database!")
                print("Aborting to prevent deleting ALL users.")
                return

            print(f"Found admin user: ID={admin[0]}, Name={admin[1]}")
            
            # Count users before delete
            cursor.execute("SELECT COUNT(*) FROM users WHERE email != %s", (ADMIN_EMAIL,))
            count = cursor.fetchone()[0]
            print(f"Found {count} non-admin users to delete.")
            
            if count > 0:
                # Delete non-admin users
                # Note: Constraints might exist. 
                # If cascade is set up, this is fine. If not, we might need to delete related data first.
                # However, usually user tables trigger cascades or we just try.
                
                # We'll try direct delete first.
                delete_query = "DELETE FROM users WHERE email != %s"
                cursor.execute(delete_query, (ADMIN_EMAIL,))
                deleted_count = cursor.rowcount
                db.connection.commit()
                print(f"Successfully deleted {deleted_count} users.")
            else:
                print("No users to delete.")

        except Exception as e:
            print(f"Error executing delete: {e}")
            # If foreign key constraint fails, we might need to clear related tables first.
            if "foreign key constraint fails" in str(e).lower():
                 print("Constraint error detected. Please verify cascade settings or manually clear related user data (subscriptions, user_books, etc.) first.")
        
        finally:
            if cursor:
                cursor.close()
            db.disconnect()
    else:
        print("Failed to connect to database.")

if __name__ == "__main__":
    delete_non_admin_users()
