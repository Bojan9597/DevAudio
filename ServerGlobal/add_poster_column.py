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
            cursor = conn.cursor(dictionary=True)
            
            # Check if column exists
            cursor.execute("SHOW COLUMNS FROM books LIKE 'posted_by_user_id'")
            result = cursor.fetchone()
            
            if not result:
                print("Adding posted_by_user_id column...")
                # Add column
                cursor.execute("ALTER TABLE books ADD COLUMN posted_by_user_id INT")
                
                # Assign default user (id=1 or first user) to existing books
                cursor.execute("SELECT id FROM users LIMIT 1")
                user = cursor.fetchone()
                if user:
                    user_id = user['id']
                    print(f"Assigning existing books to user_id: {user_id}")
                    cursor.execute("UPDATE books SET posted_by_user_id = %s WHERE posted_by_user_id IS NULL", (user_id,))
                
                # Add foreign key (optional but good practice)
                # cursor.execute("ALTER TABLE books ADD CONSTRAINT fk_posted_by FOREIGN KEY (posted_by_user_id) REFERENCES users(id)")
                
                conn.commit()
                print("Migration successful.")
            else:
                print("Column posted_by_user_id already exists.")
                
            cursor.close()
            conn.close()
    except Error as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    migrate()
