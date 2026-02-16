from database import Database
from dotenv import load_dotenv
import os

# Load env variables (same as api.py)
load_dotenv()

def migrate():
    print("Starting Streak & Badge Migration...")
    
    db = Database()
    if not db.connect():
        print("❌ Database connection failed.")
        return

    try:
        # 1. Add columns to users table
        print("Adding columns to users table...")
        db.execute_query("ALTER TABLE users ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;")
        db.execute_query("ALTER TABLE users ADD COLUMN IF NOT EXISTS last_daily_goal_at TIMESTAMP NULL;")
        
        # 2. Add Badge Category 'streak'? No, just category 'streak' in INSERT
        # Badges table already has 'category' column.

        # 3. Insert Badges
        print("Inserting Streak Badges...")
        badges = [
            ('streak', '1 Day Streak', 'Reached daily goal 1 day in a row', 'streak_1', 1),
            ('streak', '3 Day Streak', 'Reached daily goal 3 days in a row', 'streak_3', 3),
            ('streak', '7 Day Streak', 'Reached daily goal 7 days in a row', 'streak_7', 7),
            ('streak', '14 Day Streak', 'Reached daily goal 14 days in a row', 'streak_14', 14),
            ('streak', '30 Day Streak', 'Reached daily goal 30 days in a row', 'streak_30', 30),
        ]
        
        query = """
        INSERT INTO badges (category, name, description, code, threshold) 
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (code) DO NOTHING;
        """
        
        for badge in badges:
            db.execute_query(query, badge)
            print(f"  Processed badge: {badge[3]}")

        print("✅ Migration completed successfully.")

    except Exception as e:
        print(f"❌ Migration failed: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate()
