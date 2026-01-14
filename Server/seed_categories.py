import mysql.connector
from database import Database

def seed_categories():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        
        defaults = [
            ("Fiction", "fiction"),
            ("Non-Fiction", "non-fiction"),
            ("Science", "science"),
            ("History", "history"),
            ("Technology", "technology"),
            ("Biography", "biography")
        ]
        
        # Check which table exists
        table_name = None
        cursor.execute("SHOW TABLES LIKE 'categories'")
        if cursor.fetchone():
            table_name = 'categories'
        else:
            cursor.execute("SHOW TABLES LIKE 'book_categories'")
            if cursor.fetchone():
                table_name = 'book_categories'
        
        if not table_name:
            print("Error: Could not find 'categories' or 'book_categories' table.")
            # Attempt to create it?
            print("Attempting to create 'categories'...")
            cursor.execute("""
                CREATE TABLE categories (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    slug VARCHAR(255) NOT NULL UNIQUE,
                    parent_id INT DEFAULT NULL
                )
            """)
            table_name = 'categories'
            
        print(f"Seeding table '{table_name}'...")
        
        for name, slug in defaults:
            try:
                # Check for dupes
                cursor.execute(f"SELECT id FROM {table_name} WHERE slug = %s", (slug,))
                if not cursor.fetchone():
                    cursor.execute(f"INSERT INTO {table_name} (name, slug) VALUES (%s, %s)", (name, slug))
                    print(f"Inserted: {name}")
                else:
                    print(f"Skipped (exists): {name}")
            except Exception as e:
                print(f"Error inserting {name}: {e}")
                
        db.disconnect()
        print("Seeding complete.")
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    seed_categories()
