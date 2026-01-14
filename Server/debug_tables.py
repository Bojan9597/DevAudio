import mysql.connector
from database import Database

def list_tables():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        cursor.execute("SHOW TABLES")
        tables = [table[0] for table in cursor.fetchall()]
        print("Tables:", tables)
        
        # Check if 'categories' or 'book_categories' exists and has data
        for t in ['categories', 'book_categories']:
            if t in tables:
                cursor.execute(f"SELECT count(*) FROM {t}")
                count = cursor.fetchone()[0]
                print(f"Table '{t}' has {count} rows.")
                
        db.disconnect()
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    list_tables()
