"""
Migration script to remove 'programming' wrapper category
and make 'Operating Systems' and 'Programming Languages' top-level categories.
"""
from database import Database

def migrate_categories():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    try:
        # First, find the 'programming' category ID
        result = db.execute_query(
            "SELECT id FROM categories WHERE slug = 'programming' OR name LIKE '%Programming%' AND parent_id IS NULL"
        )

        if result and len(result) > 0:
            programming_id = result[0]['id']
            print(f"Found programming category with ID: {programming_id}")

            # Update all children of 'programming' to have parent_id = NULL (making them root)
            cursor = db.connection.cursor()
            cursor.execute(
                "UPDATE categories SET parent_id = NULL WHERE parent_id = %s",
                (programming_id,)
            )
            db.connection.commit()
            print(f"Updated {cursor.rowcount} categories to root level")

            # Delete the 'programming' category itself
            cursor.execute(
                "DELETE FROM categories WHERE id = %s",
                (programming_id,)
            )
            db.connection.commit()
            print("Deleted 'programming' wrapper category")

            # Verify the changes
            result = db.execute_query(
                "SELECT id, name, slug, parent_id FROM categories WHERE parent_id IS NULL ORDER BY name"
            )
            print("\nTop-level categories after migration:")
            for cat in result:
                print(f"  - {cat['name']} (slug: {cat['slug']})")
        else:
            print("No 'programming' wrapper category found - migration may have already been run")

    except Exception as e:
        print(f"Error during migration: {e}")
        db.connection.rollback()
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate_categories()
