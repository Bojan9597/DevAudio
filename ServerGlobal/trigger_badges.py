"""
Trigger badge checks for a user.
This will check all badge criteria and award any newly earned badges.
"""

from database import Database
from badge_service import BadgeService

def trigger_badges(user_id):
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        badge_service = BadgeService(db.connection)
        newly_earned = badge_service.check_badges(user_id)
        
        if newly_earned:
            print(f"✅ User {user_id} earned {len(newly_earned)} new badge(s):")
            for badge in newly_earned:
                print(f"  🏆 {badge['name']} - {badge['description']}")
        else:
            print(f"ℹ User {user_id} has no new badges to earn")
        
        return True
        
    except Exception as e:
        print(f"❌ Error checking badges: {e}")
        return False
    finally:
        db.disconnect()

if __name__ == "__main__":
    import sys
    user_id = int(sys.argv[1]) if len(sys.argv) > 1 else 5
    trigger_badges(user_id)
