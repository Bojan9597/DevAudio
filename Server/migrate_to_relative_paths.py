"""
Migration script to convert absolute URLs to relative paths in the database
"""
from database import Database

def migrate_to_relative_paths():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    try:
        cursor = db.connection.cursor()

        # List of base URLs to remove
        base_urls = [
            'http://192.168.100.15:5000',
            'http://10.247.143.89:5000',
            'http://localhost:5000'
        ]

        total_audio_updates = 0
        total_cover_updates = 0

        for base_url in base_urls:
            print(f"\nProcessing base URL: {base_url}")

            # Update audio_path
            cursor.execute(
                f"UPDATE books SET audio_path = REPLACE(audio_path, '{base_url}', '') WHERE audio_path LIKE '{base_url}%'"
            )
            audio_count = cursor.rowcount
            total_audio_updates += audio_count
            print(f"  - Updated {audio_count} audio_path entries")

            # Update cover_image_path
            cursor.execute(
                f"UPDATE books SET cover_image_path = REPLACE(cover_image_path, '{base_url}', '') WHERE cover_image_path LIKE '{base_url}%'"
            )
            cover_count = cursor.rowcount
            total_cover_updates += cover_count
            print(f"  - Updated {cover_count} cover_image_path entries")

            db.connection.commit()

        print(f"\nMigration complete!")
        print(f"  Total audio_path updates: {total_audio_updates}")
        print(f"  Total cover_image_path updates: {total_cover_updates}")

        # Verify the changes
        cursor.execute("SELECT id, title, audio_path, cover_image_path FROM books LIMIT 5")
        results = cursor.fetchall()

        print("\nSample of updated records:")
        for row in results:
            print(f"  ID {row[0]}: {row[1]}")
            print(f"    Audio: {row[2][:80] if row[2] else 'None'}...")
            print(f"    Cover: {row[3][:80] if row[3] else 'None'}...")

    except Exception as e:
        print(f"Error during migration: {e}")
        db.connection.rollback()
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate_to_relative_paths()
