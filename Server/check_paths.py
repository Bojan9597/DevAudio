from database import Database

def check_paths():
    db = Database()
    if db.connect():
        try:
            # Get playlist items for latest book
            res = db.execute_query("SELECT id, title, file_path FROM playlist_items ORDER BY id DESC LIMIT 5")
            for item in res:
                print(f"ID: {item['id']}, Title: {item['title']}, Path: '{item['file_path']}'")
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    check_paths()
