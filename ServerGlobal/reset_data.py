
import mysql.connector
from database import Database

def reset_data():
    print("WARNING: This will delete ALL users and books from the database.")
    # In automatic runs, we assume confirmation
    
    db = Database()
    if db.connect():
        cursor = None
        try:
            cursor = db.connection.cursor()
            # Disable FK checks to allow truncate/delete
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            
            tables_to_clear = [
                "users", 
                "books", 
                "user_books", 
                "user_completed_tracks", 
                "playlist_items", 
                "book_categories", 
                "pending_users",
                "playback_history"
            ]
            
            for table in tables_to_clear:
                print(f"Clearing table: {table}")
                cursor.execute(f"DELETE FROM {table}") # Use DELETE instead of TRUNCATE to avoid some permissions issues, though TRUNCATE is faster
                # Or TRUNCATE if we want to reset IDs:
                cursor.execute(f"ALTER TABLE {table} AUTO_INCREMENT = 1")

            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            db.connection.commit()
            print("Database reset successfully.")
            
        except Exception as e:
            print(f"Error resetting database: {e}")
        finally:
            if cursor:
                cursor.close()
            db.disconnect()
    else:
        print("Failed to connect to database.")

if __name__ == "__main__":
    reset_data()
