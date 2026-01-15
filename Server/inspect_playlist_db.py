from database import Database

def inspect_playlist():
    db = Database()
    if db.connect():
        # Get latest book or specific book 11
        book_id = 11
        print(f"Inspecting Playlist for Book {book_id}:")
        
        query = "SELECT id, title, file_path, track_order FROM playlist_items WHERE book_id = %s ORDER BY track_order"
        rows = db.execute_query(query, (book_id,))
        
        for row in rows:
            print(row)
            
        print("-" * 20)
        # Check Book details
        b_query = "SELECT id, title, audio_path FROM books WHERE id = %s"
        book = db.execute_query(b_query, (book_id,))
        print("Book Entry:", book)

        db.disconnect()

if __name__ == "__main__":
    inspect_playlist()
