from database import Database
import requests

def update_books_real_titles():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    # Mapping of DB index (assuming 1-10) to real books
    # Or we can update by ID if we know them. Since IDs in DB are auto-increment, and likely 1-10...
    
    # We will fetch existing books to see their IDs and update them sequentially.
    books = db.execute_query("SELECT id FROM books ORDER BY id ASC LIMIT 10")
    
    real_books = [
        {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "audio": "http://10.0.2.2:5000/static/audio/b1.mp3"},
        {"title": "1984", "author": "George Orwell", "audio": "http://10.0.2.2:5000/static/audio/b2.mp3"},
        {"title": "To Kill a Mockingbird", "author": "Harper Lee", "audio": "http://10.0.2.2:5000/static/audio/b3.mp3"},
        {"title": "The Hobbit", "author": "J.R.R. Tolkien", "audio": "http://10.0.2.2:5000/static/audio/b4.mp3"},
        {"title": "Pride and Prejudice", "author": "Jane Austen", "audio": "http://10.0.2.2:5000/static/audio/b5.mp3"},
        {"title": "The Catcher in the Rye", "author": "J.D. Salinger", "audio": "http://10.0.2.2:5000/static/audio/b6.mp3"},
        {"title": "Moby Dick", "author": "Herman Melville", "audio": "http://10.0.2.2:5000/static/audio/b7.mp3"},
        {"title": "War and Peace", "author": "Leo Tolstoy", "audio": "http://10.0.2.2:5000/static/audio/b8.mp3"},
        {"title": "The Odyssey", "author": "Homer", "audio": "http://10.0.2.2:5000/static/audio/b9.mp3"},
        {"title": "Ulysses", "author": "James Joyce", "audio": "http://10.0.2.2:5000/static/audio/b10.mp3"},
    ]

    print(f"Found {len(books)} books in DB to update.")

    for i, book_row in enumerate(books):
        if i >= len(real_books):
            break
            
        real_book = real_books[i]
        
        query = "UPDATE books SET title = %s, author = %s, audio_path = %s WHERE id = %s"
        db.execute_query(query, (real_book['title'], real_book['author'], real_book['audio'], book_row['id']))
        print(f"Updated Book {book_row['id']} to '{real_book['title']}'")

    db.disconnect()
    print("Update complete.")

if __name__ == "__main__":
    update_books_real_titles()
