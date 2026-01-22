"""
Verify that all paths in the database are now relative
"""
from database import Database

def verify_paths():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    try:
        cursor = db.connection.cursor()

        # Check for any remaining absolute URLs
        cursor.execute("""
            SELECT id, title, audio_path, cover_image_path
            FROM books
            WHERE audio_path LIKE 'http://%' OR audio_path LIKE 'https://%'
               OR cover_image_path LIKE 'http://%' OR cover_image_path LIKE 'https://%'
        """)
        absolute_urls = cursor.fetchall()

        if absolute_urls:
            print(f"WARNING: Found {len(absolute_urls)} books with absolute URLs:")
            for row in absolute_urls:
                print(f"\n  Book ID {row[0]}: {row[1]}")
                if row[2] and (row[2].startswith('http://') or row[2].startswith('https://')):
                    print(f"    Audio: {row[2]}")
                if row[3] and (row[3].startswith('http://') or row[3].startswith('https://')):
                    print(f"    Cover: {row[3]}")
        else:
            print("SUCCESS: All paths are now relative!")

        # Show sample of relative paths
        cursor.execute("SELECT id, title, audio_path, cover_image_path FROM books LIMIT 5")
        samples = cursor.fetchall()

        print(f"\nSample of {len(samples)} books with relative paths:")
        for row in samples:
            print(f"\n  Book ID {row[0]}: {row[1]}")
            print(f"    Audio: {row[2] if row[2] else 'None'}")
            print(f"    Cover: {row[3] if row[3] else 'None'}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    verify_paths()
