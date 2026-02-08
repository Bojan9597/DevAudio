import os
import random
from dotenv import load_dotenv
from database import Database

load_dotenv()

def fix_categories():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    print("Connected to DB")

    # 1. Get New Categories
    cats = db.execute_query("SELECT id FROM categories")
    if not cats:
        print("No categories found! Did you seed them?")
        return
    
    cat_ids = [c['id'] for c in cats]
    print(f"Found {len(cat_ids)} categories.")

    # 2. Get All Books
    books = db.execute_query("SELECT id, title FROM books")
    if not books:
        print("No books found.")
        return
    
    print(f"Found {len(books)} books. Reassigning...")

    # 3. Clear book_categories validation
    # We will clear table to ensure clean state
    try:
        db.execute_query("DELETE FROM book_categories")
        print("Cleared book_categories table.")
    except Exception as e:
        print(f"Error clearing book_categories: {e}")

    # 4. Reassign
    count = 0
    with db.connection.cursor() as cursor:
        for book in books:
            book_id = book['id']
            # Pick random category
            new_cat_id = random.choice(cat_ids)
            
            # Update Primary
            cursor.execute("UPDATE books SET primary_category_id = %s WHERE id = %s", (new_cat_id, book_id))
            
            # Insert into book_categories
            cursor.execute("INSERT INTO book_categories (book_id, category_id) VALUES (%s, %s)", (book_id, new_cat_id))
            
            count += 1
            if count % 10 == 0:
                print(f"Processed {count} books...")
    
    db.connection.commit()
    print("Done reassigning categories.")
    db.disconnect()

if __name__ == "__main__":
    fix_categories()
