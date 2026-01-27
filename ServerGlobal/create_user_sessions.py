from database import Database

def create_user_sessions_table():
    db = Database()
    if db.connect():
        print("Creating user_sessions table...")
        query = """
        CREATE TABLE IF NOT EXISTS user_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            refresh_token VARCHAR(500) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NULL,
            device_info VARCHAR(255),
            UNIQUE KEY unique_user (user_id) -- Enforce Single Session per user
        )
        """
        # Note: UNIQUE KEY unique_user (user_id) ensures only one row per user!
        # If we wanted multiple devices, we would use UNIQUE (refresh_token) instead.
        # But for SINGLE SESSION, we want to enforce 1 row per user.
        # Actually, ON DUPLICATE KEY UPDATE is better handled in code or via this constraint.
        # Let's use the constraint to be sure.
        
        try:
            db.execute_query(query)
            print("user_sessions table created successfully.")
        except Exception as e:
            print(f"Error creating table: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect to database")

if __name__ == "__main__":
    create_user_sessions_table()
