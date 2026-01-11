from database import Database

def main():
    db = Database()
    if db.connect():
        print("Connected. Adding slug column...")
        try:
            # Check if column exists
            result = db.execute_query("SHOW COLUMNS FROM categories LIKE 'slug'")
            if not result:
                db.execute_query("ALTER TABLE categories ADD COLUMN slug VARCHAR(100) DEFAULT NULL UNIQUE AFTER name")
                print("Column 'slug' added successfully.")
            else:
                print("Column 'slug' already exists.")
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect.")

if __name__ == "__main__":
    main()
