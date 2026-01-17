from database import Database

def create_blacklist_table():
    print("Connecting to database...")
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return

    print("Creating token_blacklist table...")
    
    # Check if table exists
    check_query = "SHOW TABLES LIKE 'token_blacklist'"
    result = db.execute_query(check_query)
    
    if not result:
        create_query = """
        CREATE TABLE token_blacklist (
            id INT AUTO_INCREMENT PRIMARY KEY,
            token VARCHAR(512) NOT NULL,
            blacklisted_on DATETIME DEFAULT CURRENT_TIMESTAMP,
            expires_at DATETIME NOT NULL,
            INDEX (token)
        )
        """
        try:
            cursor = db.connection.cursor()
            cursor.execute(create_query)
            db.connection.commit()
            cursor.close()
            print("Successfully created 'token_blacklist' table.")
        except Exception as e:
            print(f"Error creating table: {e}")
    else:
        print("'token_blacklist' table already exists.")

    db.disconnect()

if __name__ == "__main__":
    create_blacklist_table()
