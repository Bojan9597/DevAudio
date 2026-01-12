from database import Database

def check_latest_book():
    db = Database()
    if db.connect():
        try:
            # Get last book
            res = db.execute_query("SELECT id, title, audio_path FROM books ORDER BY id DESC LIMIT 1")
            if not res:
                print("No books found.")
                return

            book = res[0]
            print(f"Latest Book: ID={book['id']}, Title='{book['title']}', AudioPath='{book['audio_path']}'")
            
            # Check playlist items
            items = db.execute_query("SELECT * FROM playlist_items WHERE book_id = %s", (book['id'],))
            print(f"Playlist Items Count: {len(items) if items else 0}")
            if items:
                for item in items:
                    print(f" - {item['title']} (Order: {item['track_order']})")
            
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    check_latest_book()
