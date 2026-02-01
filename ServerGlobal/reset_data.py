#!/usr/bin/env python3
"""Reset all data in the PostgreSQL database."""

from database import Database

def reset_data():
    print("WARNING: This will delete ALL users and books from the database.")
    # In automatic runs, we assume confirmation
    
    db = Database()
    if db.connect():
        try:
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
                # Use TRUNCATE with CASCADE to handle foreign keys in PostgreSQL
                db.execute_query(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE")

            print("Database reset successfully.")
            
        except Exception as e:
            print(f"Error resetting database: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect to database.")

if __name__ == "__main__":
    reset_data()
