from database import Database

def migrate():
    db = Database()
    if not db.connect():
        print("Failed to connect to DB")
        return

    try:
        print("Creating pending_users table...")
        create_table_query = """
        CREATE TABLE IF NOT EXISTS pending_users (
            email VARCHAR(255) PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            verification_code VARCHAR(6) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """
        db.execute_query(create_table_query)
        print("Table created successfully.")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.disconnect()

if __name__ == "__main__":
    migrate()
