import json
import os
from database import Database

# Path to the JSON file
JSON_FILE_PATH = os.path.join(os.path.dirname(__file__), '../hello_flutter/lib/data/books.json')

def load_json_data():
    try:
        with open(JSON_FILE_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return None

def get_category_id_by_slug(db, slug):
    """Returns ID for a given slug."""
    if not slug:
        return None
    result = db.execute_query("SELECT id FROM categories WHERE slug = %s", (slug,))
    if result and len(result) > 0:
        return result[0]['id']
    return None

def main():
    print("Starting book migration...")
    db = Database()
    if not db.connect():
        return

    # Clear existing books (optional)
    db.execute_query("SET FOREIGN_KEY_CHECKS = 0")
    db.execute_query("TRUNCATE TABLE books")
    db.execute_query("TRUNCATE TABLE book_categories")
    db.execute_query("SET FOREIGN_KEY_CHECKS = 1")

    books = load_json_data()
    if not books:
        return

    for book in books:
        title = book.get('title')
        author = book.get('author')
        audio_path = book.get('audioUrl')
        cat_slug = book.get('categoryId')
        sub_slugs = book.get('subcategoryIds', [])

        # Get primary category ID
        primary_cat_id = get_category_id_by_slug(db, cat_slug)
        if not primary_cat_id:
            print(f"Warning: Primary category slug '{cat_slug}' not found for book '{title}'.")

        # Insert book
        query = "INSERT INTO books (title, author, audio_path, primary_category_id) VALUES (%s, %s, %s, %s)"
        try:
            cursor = db.connection.cursor()
            cursor.execute(query, (title, author, audio_path, primary_cat_id))
            db.connection.commit()
            book_id = cursor.lastrowid
            cursor.close()
            print(f"Inserted Book: {title} (ID: {book_id})")

            # Insert subcategories logic
            # Note: We can insert the primary category into book_categories too, or keep it separate.
            # The app likely uses subcategoryIds check for filtering too, so let's insert ALL into book_categories
            # to make filtering by "any category" easy, OR strictly follow the JSON structure.
            # The JSON separates them. The App logic:
            # if (book.categoryId == clickedCategoryId) return true;
            # if (book.subcategoryIds.contains(clickedCategoryId)) return true;
            # So if I only put subcategories in `book_categories`, I need to expose `primary_category` separately in API.
            # I'll stick to inserting ONLY subcategories into `book_categories` to match JSON structure strictly as interpreted.
            
            for sub_slug in sub_slugs:
                sub_id = get_category_id_by_slug(db, sub_slug)
                if sub_id:
                    cursor = db.connection.cursor()
                    cursor.execute("INSERT INTO book_categories (book_id, category_id) VALUES (%s, %s)", (book_id, sub_id))
                    db.connection.commit()
                    cursor.close()
        except Exception as e:
            print(f"Error inserting book '{title}': {e}")

    db.disconnect()
    print("Book migration finished.")

if __name__ == "__main__":
    main()
