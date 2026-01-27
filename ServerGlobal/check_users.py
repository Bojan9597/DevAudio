import mysql.connector
from database import Database

def check_users():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        
        print("Checking 'users' table...")
        cursor.execute("SELECT id, email, name FROM users")
        users = cursor.fetchall()
        
        if not users:
            print("Table 'users' is EMPTY. This is why Upload fails (Invalid User ID).")
        else:
            print(f"Found {len(users)} users:")
            for u in users:
                print(f" - ID: {u[0]}, Email: {u[1]}")
                
        db.disconnect()
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    check_users()
