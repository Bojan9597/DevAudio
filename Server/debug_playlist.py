from database import Database

def debug_playlists():
    db = Database()
    if not db.connect():
        print("Failed to connect")
        return

    with open("debug_output.txt", "w") as f:
        try:
            # Check Table Schemas
            f.write("Checking Schemas...\n")
            res = db.execute_query("SHOW CREATE TABLE playlist_items")
            if res:
                 f.write(f"Playlist Items Schema: {res}\n")
            
            res = db.execute_query("SHOW CREATE TABLE users")
            if res:
                 f.write(f"Users Schema: {res}\n")


            # Test get_playlist query logic
            f.write("\n--- Testing get_playlist query for Book 38 ---\n")
            user_id = 1
            book_id = 38
            
            query = """
                    SELECT p.*, 
                           CASE WHEN uct.id IS NOT NULL THEN TRUE ELSE FALSE END as is_completed
                    FROM playlist_items p
                    LEFT JOIN user_completed_tracks uct ON p.id = uct.track_id AND uct.user_id = %s
                    WHERE p.book_id = %s 
                    ORDER BY p.track_order ASC
                 """
            f.write(f"Executing Query with user_id={user_id}, book_id={book_id}\n")
            
            result = db.execute_query(query, (user_id, book_id))
            if result:
                f.write(f"Result Count: {len(result)}\n")
                for r in result:
                    f.write(f"Row: {r}\n")
            else:
                f.write("Result is empty!\n")
            f.write("\n") # Added a newline for separation

            # Check all books
            books = db.execute_query("SELECT id, title FROM books ORDER BY id DESC LIMIT 5")
            f.write("\n--- Recent Books ---\n")
            for b in books:
                # Check actual count in playlist_items
                c_query = "SELECT COUNT(*) as c FROM playlist_items WHERE book_id = %s"
                real_count = db.execute_query(c_query, (b['id'],))[0]['c']
                f.write(f"ID: {b['id']}, Title: {b['title']}, Real Items: {real_count}\n")

            # Dump playlist items
            f.write("\n--- all playlist_items ---\n")
            items = db.execute_query("SELECT * FROM playlist_items ORDER BY id DESC LIMIT 10")
            for item in items:
                f.write(f"Item: {item}\n")

        except Exception as e:
            f.write(f"Error: {e}\n")
    
    db.disconnect()

if __name__ == "__main__":
    debug_playlists()
