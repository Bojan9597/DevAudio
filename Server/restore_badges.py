"""
Restore badges to the database.
This script re-creates the standard badges that should always be in the system.
"""

from database import Database

def restore_badges():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor()
        
        print("Restoring badges...")
        
        # Check if badges already exist
        cursor.execute("SELECT COUNT(*) as count FROM badges")
        result = cursor.fetchone()
        
        if result[0] > 0:
            print(f"⚠ Badges already exist ({result[0]} badges). Skipping restoration.")
            cursor.close()
            db.disconnect()
            return True
        
        # Define the standard badges
        badges = [
            # Reading badges
            ("Reading", "First Book", "Complete your first audiobook", "read_1", 1),
            ("Reading", "Bookworm", "Complete 5 audiobooks", "read_5", 5),
            ("Reading", "Scholar", "Complete 10 audiobooks", "read_10", 10),
            ("Reading", "Master Reader", "Complete 25 audiobooks", "read_25", 25),
            ("Reading", "Library Champion", "Complete 50 audiobooks", "read_50", 50),
            
            # Purchasing badges
            ("Collection", "Book Collector", "Purchase 5 audiobooks", "buy_5", 5),
            ("Collection", "Library Builder", "Purchase 10 audiobooks", "buy_10", 10),
            ("Collection", "Audiobook Enthusiast", "Purchase 25 audiobooks", "buy_25", 25),
        ]
        
        # Insert badges
        insert_query = """
            INSERT INTO badges (category, name, description, code, threshold)
            VALUES (%s, %s, %s, %s, %s)
        """
        
        for badge in badges:
            cursor.execute(insert_query, badge)
            print(f"  ✓ Created badge: {badge[1]}")
        
        db.connection.commit()
        cursor.close()
        
        print(f"\n✅ Successfully restored {len(badges)} badges!")
        return True
        
    except Exception as e:
        print(f"❌ Error restoring badges: {e}")
        db.connection.rollback()
        return False
    finally:
        db.disconnect()

if __name__ == "__main__":
    restore_badges()
