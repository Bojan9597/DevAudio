import mysql.connector
from badge_service import BadgeService
from database import Database

def backfill_data():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    try:
        print("--- Starting Backfill ---")

        # 1. Backfill is_read based on position vs duration
        print("Updating is_read status...")
        # Join to get duration. 
        # Note: MySQL update with join
        update_is_read_query = """
            UPDATE user_books ub
            JOIN books b ON ub.book_id = b.id
            SET ub.is_read = 1, ub.completed_at = ub.last_accessed_at
            WHERE ub.last_played_position_seconds >= (b.duration_seconds * 0.95)
              AND b.duration_seconds > 0
              AND (ub.is_read = 0 OR ub.is_read IS NULL)
        """
        updated = db.execute_query(update_is_read_query)
        print(f"Updated {updated} books to is_read=1")

        # 2. Trigger Badge Checks for ALL users
        print("Checking badges for all users...")
        users = db.execute_query("SELECT id, email FROM users")
        
        # Close and Reconnect to ensure clean state (fix Unread result errors)
        db.disconnect()
        if not db.connect():
             print("Failed to reconnect")
             return
        
        badge_service = BadgeService(db.connection)
        
        for user in users:
            uid = user['id']
            email = user['email']
            print(f"Checking for user {email} (ID: {uid})...")
            
            new_badges = badge_service.check_badges(uid)
            if new_badges:
                print(f"  -> Earned: {', '.join(new_badges)}")
            else:
                print("  -> No new badges.")

        print("--- Backfill Complete ---")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    backfill_data()
