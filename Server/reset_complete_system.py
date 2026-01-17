"""
Complete system reset script.
Deletes all data from database and removes all uploaded files.
"""

from database import Database
import os
import shutil

def reset_database():
    """Delete all data from database tables"""
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor()
        
        print("Resetting database...")
        
        # Disable foreign key checks temporarily
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # Delete data from all tables
        tables_to_clear = [
            'playback_history',
            'user_quiz_results',
            'quiz_questions',
            'quizzes',
            'user_completed_tracks',
            'user_track_progress',
            'user_badges',
            'badges',
            'favorites',
            'user_books',
            'playlist_items',
            'book_categories',
            'books',
            'pending_users',
            'users'
        ]
        
        for table in tables_to_clear:
            try:
                cursor.execute(f"DELETE FROM {table}")
                print(f"  ✓ Cleared {table}")
            except Exception as e:
                print(f"  ⚠ Could not clear {table}: {e}")
        
        # Re-enable foreign key checks
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        db.connection.commit()
        cursor.close()
        
        print("\n✅ Database reset complete!")
        return True
        
    except Exception as e:
        print(f"❌ Error resetting database: {e}")
        db.connection.rollback()
        return False
    finally:
        db.disconnect()

def delete_uploaded_files():
    """Delete all uploaded files"""
    print("\nDeleting uploaded files...")
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    static_dir = os.path.join(base_dir, 'static')
    
    folders_to_clear = [
        os.path.join(static_dir, 'AudioBooks'),
        os.path.join(static_dir, 'BookCovers'),
        os.path.join(static_dir, 'profilePictures')
    ]
    
    for folder in folders_to_clear:
        if os.path.exists(folder):
            try:
                # Remove all contents but keep the folder
                for item in os.listdir(folder):
                    item_path = os.path.join(folder, item)
                    if os.path.isfile(item_path):
                        os.remove(item_path)
                    elif os.path.isdir(item_path):
                        shutil.rmtree(item_path)
                print(f"  ✓ Cleared {folder}")
            except Exception as e:
                print(f"  ⚠ Error clearing {folder}: {e}")
        else:
            print(f"  ℹ {folder} does not exist")
    
    print("\n✅ File cleanup complete!")

def main():
    print("=" * 60)
    print("COMPLETE SYSTEM RESET")
    print("=" * 60)
    print("\nThis will:")
    print("  - Delete ALL users, books, playlists, quizzes, badges")
    print("  - Delete ALL playback history and progress")
    print("  - Delete ALL uploaded audio files, covers, and profile pictures")
    print("\n" + "=" * 60)
    
    confirm = input("\nType 'RESET' to confirm: ")
    
    if confirm != 'RESET':
        print("\n❌ Reset cancelled.")
        return
    
    print("\nProceeding with reset...\n")
    
    # Reset database
    db_success = reset_database()
    
    # Delete files
    delete_uploaded_files()
    
    if db_success:
        print("\n" + "=" * 60)
        print("✅ SYSTEM RESET COMPLETE!")
        print("=" * 60)
        print("\nYou can now:")
        print("  1. Restart the API server")
        print("  2. Register new users")
        print("  3. Upload new books")
    else:
        print("\n❌ Reset completed with errors. Check messages above.")

if __name__ == "__main__":
    main()
