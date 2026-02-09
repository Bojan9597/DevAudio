import json
import os
from database import Database
from dotenv import load_dotenv
load_dotenv()

def sync_categories():
    # Path to categories.json
    # Check local dir first (for server)
    json_path = os.path.join(os.path.dirname(__file__), 'categories.json')
    if not os.path.exists(json_path):
        # Fallback to dev path
        json_path = os.path.join(os.path.dirname(__file__), '../hello_flutterGlobal/lib/data/categories.json')
    
    if not os.path.exists(json_path):
        print(f"Error: Could not find {json_path}")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        categories_data = json.load(f)

    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    print("Connected to database. Starting sync...")
    
    # Keep track of active category IDs to delete obsolete ones later
    active_ids = set()

    def process_category(cat_data, parent_id=None):
        slug = cat_data['id']
        name = cat_data['title']
        
        # Check if exists
        existing = db.execute_query("SELECT id FROM categories WHERE slug = %s", (slug,))
        
        if existing:
            cat_id = existing[0]['id']
            # Update name and parent if changed
            db.execute_query(
                "UPDATE categories SET name = %s, parent_id = %s WHERE id = %s",
                (name, parent_id, cat_id)
            )
            # print(f"Updated: {name} ({slug})")
        else:
            # Insert
            cursor = db.connection.cursor()
            cursor.execute(
                "INSERT INTO categories (name, slug, parent_id) VALUES (%s, %s, %s) RETURNING id",
                (name, slug, parent_id)
            )
            cat_id = cursor.fetchone()[0]
            db.connection.commit()
            cursor.close()
            print(f"Inserted: {name} ({slug})")
            
        active_ids.add(cat_id)
        
        # Process children
        if 'children' in cat_data:
            for child in cat_data['children']:
                process_category(child, cat_id)

    try:
        # 1. Upsert all categories from JSON
        for root_cat in categories_data:
            process_category(root_cat)
            
        print(f"Synced {len(active_ids)} categories.")

        # 2. Delete obsolete categories
        # Get all IDs currently in DB
        all_cats = db.execute_query("SELECT id, name, slug FROM categories")
        all_ids = set(c['id'] for c in all_cats)
        
        to_delete = all_ids - active_ids
        
        if to_delete:
            print(f"Deleting {len(to_delete)} obsolete categories...")
            # Delete in batch? Or one by one to be safe?
            # PostgreSQL can handle "WHERE id IN (...)"
            
            # Since we have parent-child relationships, we might need to be careful if we didn't use ON DELETE CASCADE.
            # But clean_database_setup.sql showed:
            # CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
            # So deleting a parent should delete children. 
            # However, if we delete a child first, it's fine.
            # If we try to delete simple IDs, it should work.
            
            format_strings = ','.join(['%s'] * len(to_delete))
            delete_query = f"DELETE FROM categories WHERE id IN ({format_strings})"
            
            # We need to execute. Database class might not handle list for IN clause well in execute_query directly without tuple
            params = tuple(to_delete)
            
            # Use raw cursor for safety with IN clause
            cursor = db.connection.cursor()
            cursor.execute(delete_query, params)
            deleted_count = cursor.rowcount
            db.connection.commit()
            cursor.close()
            
            print(f"Deleted {deleted_count} categories.")
        else:
            print("No obsolete categories to delete.")
            
    except Exception as e:
        print(f"Error during sync: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    sync_categories()
