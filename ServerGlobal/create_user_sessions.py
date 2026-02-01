#!/usr/bin/env python3
"""Create the user_sessions table for PostgreSQL."""

from database import Database

def create_user_sessions_table():
    db = Database()
    if db.connect():
        print("Creating user_sessions table...")
        query = """
        CREATE TABLE IF NOT EXISTS user_sessions (
            id SERIAL PRIMARY KEY,
            user_id INT NOT NULL UNIQUE,
            refresh_token VARCHAR(500) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NULL,
            device_info VARCHAR(255)
        )
        """
        # Note: UNIQUE on user_id ensures only one session per user (Single Session Policy)
        
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
