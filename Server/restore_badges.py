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
        
        # Define the original badges (from backup)
        badges = [
            ('read', 'Read 1 Book', 'Finished your first book', 'read_1', 1),
            ('read', 'Read 2 Books', 'Finished 2 books', 'read_2', 2),
            ('read', 'Read 5 Books', 'Finished 5 books', 'read_5', 5),
            ('read', 'Read 10 Books', 'Finished 10 books', 'read_10', 10),
            ('buy', 'Collector I', 'Bought your first book', 'buy_1', 1),
            ('buy', 'Collector II', 'Bought 2 books', 'buy_2', 2),
            ('buy', 'Collector III', 'Bought 5 books', 'buy_5', 5),
            ('buy', 'Collector IV', 'Bought 10 books', 'buy_10', 10),
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
