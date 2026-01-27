from database import Database
import os
import shutil

def reset_db():
    print("Resetting User Data (Keeping Categories/Badges)...")
    db = Database()
    if not db.connect():
        print("Failed to connect")
        return

    try:
        # Disable foreign key checks to allow arbitrary deletion order (or careful order)
        db.execute_query("SET FOREIGN_KEY_CHECKS = 0")
        
        tables_to_clear = [
            "user_completed_tracks",
            "playlist_items",
            "playback_history",
            "user_books",
            "favorites",
            "user_badges",
            "pending_users",
            "books",
            "users"
        ]
        
        for table in tables_to_clear:
            print(f"Clearing {table}...")
            db.execute_query(f"TRUNCATE TABLE {table}")
            
        db.execute_query("SET FOREIGN_KEY_CHECKS = 1")
        print("Database tables cleared.")
        
        # Clear Files
        base_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Clear AudioBooks
        audio_dir = os.path.join(base_dir, 'static', 'AudioBooks')
        if os.path.exists(audio_dir):
            for item in os.listdir(audio_dir):
                item_path = os.path.join(audio_dir, item)
                # Keep .gitkeep or similar if exists, otherwise wipe
                if item == ".gitkeep": continue
                if os.path.isdir(item_path):
                    shutil.rmtree(item_path)
                else:
                    os.remove(item_path)
            print("AudioBooks folder cleared.")

        # Clear Profile Pictures
        pfp_dir = os.path.join(base_dir, 'static', 'profilePictures')
        if os.path.exists(pfp_dir):
             for item in os.listdir(pfp_dir):
                item_path = os.path.join(pfp_dir, item)
                if item == ".gitkeep": continue
                os.remove(item_path)
             print("ProfilePictures folder cleared.")

        # Clear BookCovers
        covers_dir = os.path.join(base_dir, 'static', 'BookCovers')
        if os.path.exists(covers_dir):
             for item in os.listdir(covers_dir):
                item_path = os.path.join(covers_dir, item)
                if item == ".gitkeep": continue
                os.remove(item_path)
             print("BookCovers folder cleared.")
             
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    reset_db()
