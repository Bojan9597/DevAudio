from database import Database
import sys

def migrate():
    print("Starting migration...")
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        sys.exit(1)
        
    try:
        # 1. Create background_music table
        print("Creating background_music table...")
        create_table_query = """
            CREATE TABLE IF NOT EXISTS background_music (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                file_path VARCHAR(255) NOT NULL,
                is_default BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        db.execute_query(create_table_query)
        print("background_music table created.")
        
        # 2. Add background_music_id to books
        print("Altering books table...")
        try:
             alter_query = "ALTER TABLE books ADD COLUMN background_music_id INT DEFAULT NULL"
             db.execute_query(alter_query)
             print("Column background_music_id added.")
        except Exception as e:
             if "DuplicateColumn" in str(e) or "already exists" in str(e):
                 print("Column background_music_id already exists.")
             else:
                 print(f"Column addition warning: {e}")

    except Exception as e:
        print(f"Migration error: {e}")
        # Don't exit with 1 if table already exists logic handled above, but here we catch generic.
        # But we want to see output.
        pass 
    finally:
        db.disconnect()
        print("Done.")

if __name__ == "__main__":
    migrate()
