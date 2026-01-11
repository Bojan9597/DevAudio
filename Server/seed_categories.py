import json
import os
from database import Database

# Path to the JSON file
JSON_FILE_PATH = os.path.join(os.path.dirname(__file__), '../hello_flutter/lib/data/categories.json')

def load_json_data():
    """Reads the JSON file and returns data."""
    try:
        with open(JSON_FILE_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: JSON file not found at {JSON_FILE_PATH}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
        return None

def insert_category(db, category, parent_id=None):
    """Recursively inserts categories into the database."""
    name = category.get('title')
    slug = category.get('id') # The string ID from JSON (e.g., 'python', 'linux')
    
    if not name:
        print(f"Skipping category with no title: {category}")
        return

    # Prepare query
    query = "INSERT INTO categories (name, slug, parent_id) VALUES (%s, %s, %s)"
    params = (name, slug, parent_id)

    # Execute insert
    try:
        cursor = db.connection.cursor()
        cursor.execute(query, params)
        db.connection.commit()
        category_id = cursor.lastrowid
        cursor.close()
        print(f"Inserted: {name} (Slug: {slug}, ID: {category_id}, Parent: {parent_id})")

        # Process children recursively
        children = category.get('children', [])
        for child in children:
            insert_category(db, child, parent_id=category_id)
            
    except Exception as e:
        print(f"Error inserting category '{name}': {e}")

def main():
    print("Starting category migration...")
    
    db = Database()
    if not db.connect():
        print("Failed to connect to database.")
        return

    # Clear existing categories (optional, but good for idempotent runs/testing)
    # WARNING: This deletes everything in the table!
    print("Clearing existing categories...")
    db.execute_query("SET FOREIGN_KEY_CHECKS = 0")
    db.execute_query("TRUNCATE TABLE categories")
    db.execute_query("SET FOREIGN_KEY_CHECKS = 1")

    data = load_json_data()
    if data:
        for category in data:
            insert_category(db, category)
        print("Migration completed.")
    else:
        print("No data found to migrate.")

    db.disconnect()

if __name__ == "__main__":
    main()
