"""
Restore badges from backup to current database
"""
from database import Database

def restore_badges():
    """Insert badges from backup SQL into current database"""
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor()
        
        print("Restoring badges...")
        
        # Badges from backup SQL
        badges = [
            # Read badges
            ('read', 'Read 1 Book', 'Finished your first book', 'read_1', 1),
            ('read', 'Read 2 Books', 'Finished 2 books', 'read_2', 2),
            ('read', 'Read 5 Books', 'Finished 5 books', 'read_5', 5),
            ('read', 'Read 10 Books', 'Finished 10 books', 'read_10', 10),
            # Buy badges
            ('buy', 'Collector I', 'Bought your first book', 'buy_1', 1),
            ('buy', 'Collector II', 'Bought 2 books', 'buy_2', 2),
            ('buy', 'Collector III', 'Bought 5 books', 'buy_5', 5),
            ('buy', 'Collector IV', 'Bought 10 books', 'buy_10', 10),
        ]
        
        insert_query = """
            INSERT INTO badges (category, name, description, code, threshold)
            VALUES (%s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                name = VALUES(name),
                description = VALUES(description),
                threshold = VALUES(threshold)
        """
        
        for badge in badges:
            cursor.execute(insert_query, badge)
            print(f"  ✓ Inserted/updated badge: {badge[1]} ({badge[3]})")
        
        db.connection.commit()
        cursor.close()
        
        print(f"\n✅ Restored {len(badges)} badges!")
        return True
        
    except Exception as e:
        print(f"❌ Error restoring badges: {e}")
        db.connection.rollback()
        return False
    finally:
        db.disconnect()

def verify_badges():
    """Verify badges are in the database"""
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return
    
    try:
        cursor = db.connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM badges ORDER BY category, threshold")
        badges = cursor.fetchall()
        cursor.close()
        
        print("\n📛 Current badges in database:")
        for badge in badges:
            print(f"  [{badge['category']}] {badge['name']} - threshold: {badge['threshold']}")
        
        return len(badges) > 0
        
    except Exception as e:
        print(f"❌ Error verifying badges: {e}")
        return False
    finally:
        db.disconnect()

if __name__ == '__main__':
    restore_badges()
    verify_badges()
