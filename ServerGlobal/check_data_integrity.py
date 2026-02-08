import os
import json
from dotenv import load_dotenv

load_dotenv()

from database import Database

def check_integrity():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    print("Connected to DB")
    
    # Check Categories (New History Ones)
    print("\n--- Categories ---")
    cats = db.execute_query("SELECT id, name, slug FROM categories LIMIT 5")
    if cats:
        for c in cats:
            print(c)
    else:
        print("No categories found!")

    # Check Books (Existing Data)
    print("\n--- Books (Sample) ---")
    books = db.execute_query("SELECT id, title, primary_category_id FROM books LIMIT 5")
    if books:
        for b in books:
            print(f"Book: {b['title']} (ID: {b['id']}), Primary Cat ID: {b['primary_category_id']}")
            
            # Check if primary_category_id exists in categories
            if b['primary_category_id']:
                cat_check = db.execute_query("SELECT id FROM categories WHERE id = %s", (b['primary_category_id'],))
                if not cat_check:
                    print(f"  -> WARNING: Primary Category ID {b['primary_category_id']} NOT FOUND in categories table!")
    else:
        print("No books found!")

    # Check Book Categories (Many-to-Many)
    print("\n--- Book Categories (Sample) ---")
    bc = db.execute_query("SELECT book_id, category_id FROM book_categories LIMIT 5")
    if bc:
        for row in bc:
            print(f"Book ID: {row['book_id']} -> Cat ID: {row['category_id']}")
            
            cat_check = db.execute_query("SELECT id FROM categories WHERE id = %s", (row['category_id'],))
            if not cat_check:
                print(f"  -> WARNING: Category ID {row['category_id']} NOT FOUND in categories table!")
    else:
        print("No book_categories found or limit reached.")

    db.disconnect()

if __name__ == "__main__":
    check_integrity()
