"""
Migration script to recalculate book durations from playlist items for existing books.
This script will:
1. Find all books with playlist items but duration = 0
2. Calculate total duration from all track durations in playlist_items
3. Update the books table with the correct total duration
"""

from database import Database

def migrate_playlist_durations():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False
    
    try:
        cursor = db.connection.cursor(dictionary=True)
        
        # Get all books that have playlist items
        query = """
            SELECT DISTINCT b.id, b.title
            FROM books b
            WHERE EXISTS (SELECT 1 FROM playlist_items WHERE book_id = b.id)
        """
        
        cursor.execute(query)
        books_with_playlists = cursor.fetchall()
        
        print(f"Found {len(books_with_playlists)} books with playlist items")
        
        updated_count = 0
        
        for book in books_with_playlists:
            book_id = book['id']
            book_title = book['title']
            
            # Get all track durations for this book
            duration_query = """
                SELECT SUM(duration_seconds) as total_duration
                FROM playlist_items
                WHERE book_id = %s AND duration_seconds > 0
            """
            
            cursor.execute(duration_query, (book_id,))
            result = cursor.fetchone()
            
            if result and result['total_duration']:
                total_duration = int(result['total_duration'])
                
                # Update the book
                update_query = "UPDATE books SET duration_seconds = %s WHERE id = %s"
                cursor.execute(update_query, (total_duration, book_id))
                db.connection.commit()
                
                print(f"Updated book '{book_title}' (ID: {book_id}) with total duration: {total_duration}s")
                updated_count += 1
            else:
                print(f"Skipped book '{book_title}' (ID: {book_id}) - no track durations found")
        
        cursor.close()
        print(f"\nMigration complete. Updated {updated_count} books.")
        return True
        
    except Exception as e:
        print(f"Error during migration: {e}")
        return False
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate_playlist_durations()
