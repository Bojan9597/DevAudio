"""
Remove collector badges and reset user progress
"""
from database import Database

def remove_collector_badges_and_reset_progress():
    """Remove collector badges and reset all user progress"""
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor()
        
        print("=" * 50)
        print("REMOVING COLLECTOR BADGES AND RESETTING PROGRESS")
        print("=" * 50)
        
        # Disable foreign key checks temporarily
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # 1. Remove collector badges from user_badges table first
        print("\n1. Removing earned collector badges from users...")
        cursor.execute("""
            DELETE ub FROM user_badges ub
            JOIN badges b ON ub.badge_id = b.id
            WHERE b.category = 'buy'
        """)
        print(f"   ✓ Removed {cursor.rowcount} earned collector badges")
        
        # 2. Remove collector badges from badges table
        print("\n2. Removing collector badges from database...")
        cursor.execute("DELETE FROM badges WHERE category = 'buy'")
        print(f"   ✓ Removed {cursor.rowcount} collector badge definitions")
        
        # 3. Reset user_books table (books owned, positions, is_read status)
        print("\n3. Clearing user_books (owned books and reading progress)...")
        cursor.execute("DELETE FROM user_books")
        print(f"   ✓ Cleared {cursor.rowcount} records")
        
        # 4. Reset playback_history
        print("\n4. Clearing playback_history...")
        cursor.execute("DELETE FROM playback_history")
        print(f"   ✓ Cleared {cursor.rowcount} records")
        
        # 5. Reset user_completed_tracks
        print("\n5. Clearing user_completed_tracks...")
        cursor.execute("DELETE FROM user_completed_tracks")
        print(f"   ✓ Cleared {cursor.rowcount} records")
        
        # 6. Reset user_track_progress
        print("\n6. Clearing user_track_progress...")
        try:
            cursor.execute("DELETE FROM user_track_progress")
            print(f"   ✓ Cleared {cursor.rowcount} records")
        except:
            print("   ℹ Table doesn't exist, skipping")
        
        # 7. Reset favorites
        print("\n7. Clearing favorites...")
        cursor.execute("DELETE FROM favorites")
        print(f"   ✓ Cleared {cursor.rowcount} records")
        
        # 8. Reset user_badges (all earned badges)
        print("\n8. Clearing all earned user badges...")
        cursor.execute("DELETE FROM user_badges")
        print(f"   ✓ Cleared {cursor.rowcount} records")
        
        # 9. Reset quiz results
        print("\n9. Clearing quiz results...")
        try:
            cursor.execute("DELETE FROM user_quiz_results")
            print(f"   ✓ Cleared {cursor.rowcount} records")
        except:
            print("   ℹ Table doesn't exist, skipping")
        
        # Re-enable foreign key checks
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        db.connection.commit()
        cursor.close()
        
        print("\n" + "=" * 50)
        print("✅ DONE! Collector badges removed and progress reset.")
        print("=" * 50)
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.connection.rollback()
        return False
    finally:
        db.disconnect()

def verify_badges():
    """Show remaining badges"""
    db = Database()
    if not db.connect():
        return
    
    try:
        cursor = db.connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM badges ORDER BY category, threshold")
        badges = cursor.fetchall()
        cursor.close()
        
        print("\n📛 Remaining badges in database:")
        for badge in badges:
            print(f"   [{badge['category']}] {badge['name']} - threshold: {badge['threshold']}")
        
        if not badges:
            print("   (no badges)")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == '__main__':
    remove_collector_badges_and_reset_progress()
    verify_badges()
