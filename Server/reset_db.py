from database import Database

def reset_database():
    db = Database()
    if db.connect():
        try:
            print("Resetting database...")
            
            # Disable FK checks to allow truncation in any order (though we try to be ordered)
            db.execute_query("SET FOREIGN_KEY_CHECKS = 0")
            
            tables_to_clear = [
                "playlist_items",
                "user_badges",
                "user_books",
                "listen_history",
                "favorites",
                "pending_users",
                "books",
                "users",
                # "badges", # Keep badges metadata? User said "users and books".
                # "categories" # Keep categories?
            ]
            
            for table in tables_to_clear:
                print(f"Clearing table: {table}")
                db.execute_query(f"DELETE FROM {table}") # Use DELETE FROM to be safer than TRUNCATE in some SQL modes or if FKs are strict?
                # TRUNCATE is faster and resets auto_increment.
                # db.execute_query(f"TRUNCATE TABLE {table}")
            
            # Re-enable FK checks
            db.execute_query("SET FOREIGN_KEY_CHECKS = 1")
            
            print("Database reset complete.")
            
        except Exception as e:
            print(f"Error resetting database: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    reset_database()
