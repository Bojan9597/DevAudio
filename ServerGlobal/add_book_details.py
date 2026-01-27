import mysql.connector
from mysql.connector import Error

def migrate():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            database="audiobooks",
            user="root",
            password="Pijanista123!"
        )
        if conn.is_connected():
            cursor = conn.cursor()
            
            # Add description
            try:
                cursor.execute("ALTER TABLE books ADD COLUMN description TEXT")
                print("Added description column.")
            except Error as e:
                print(f"Skipping description (maybe exists): {e}")

            # Add price
            try:
                cursor.execute("ALTER TABLE books ADD COLUMN price DECIMAL(10,2) DEFAULT 0.00")
                print("Added price column.")
            except Error as e:
                print(f"Skipping price (maybe exists): {e}")

            conn.commit()
            print("Migration successful.")
            cursor.close()
            conn.close()
    except Error as e:
        print(f"Connection Error: {e}")

if __name__ == "__main__":
    migrate()
