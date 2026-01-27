from database import Database

def main():
    db = Database()
    if db.connect():
        print("Connected. Updating books table schema...")
        try:
            # Check if column exists
            result = db.execute_query("SHOW COLUMNS FROM books LIKE 'primary_category_id'")
            if not result:
                # Add column
                db.execute_query("ALTER TABLE books ADD COLUMN primary_category_id INT UNSIGNED DEFAULT NULL")
                # Add foreign key (optional but good practice)
                db.execute_query("ALTER TABLE books ADD CONSTRAINT fk_books_primary_category FOREIGN KEY (primary_category_id) REFERENCES categories(id) ON DELETE SET NULL")
                print("Column 'primary_category_id' added successfully.")
            else:
                print("Column 'primary_category_id' already exists.")
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect.")

if __name__ == "__main__":
    main()
