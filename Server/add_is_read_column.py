from database import Database

def add_is_read_column():
    db = Database()
    if db.connect():
        try:
            # Check if column exists
            check_query = "SHOW COLUMNS FROM user_books LIKE 'is_read'"
            result = db.execute_query(check_query)
            
            if not result:
                print("Adding is_read column to user_books...")
                alter_query = "ALTER TABLE user_books ADD COLUMN is_read BOOLEAN DEFAULT FALSE"
                cursor = db.connection.cursor()
                cursor.execute(alter_query)
                db.connection.commit()
                cursor.close()
                print("Column added successfully.")
            else:
                print("Column is_read already exists.")
                
        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()

if __name__ == "__main__":
    add_is_read_column()
