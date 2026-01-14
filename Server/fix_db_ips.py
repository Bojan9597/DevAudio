import mysql.connector
from database import Database

def fix_ips():
    db = Database()
    if db.connect():
        cursor = db.connection.cursor()
        
        wrong_ip = "10.75.60.89"
        correct_ip = "10.177.190.89"
        
        print(f"Replacing {wrong_ip} -> {correct_ip} in database...")
        
        updates = [
            ("books", "audio_path"),
            ("books", "cover_image_path"),
            ("playlist_items", "audio_path"),
            ("users", "profile_picture")
        ]
        
        for table, col in updates:
            try:
                # Check if column exists (users table optional columns etc)
                cursor.execute(f"SHOW COLUMNS FROM {table} LIKE '{col}'")
                if cursor.fetchone():
                    # Update
                    query = f"UPDATE {table} SET {col} = REPLACE({col}, '{wrong_ip}', '{correct_ip}') WHERE {col} LIKE '%{wrong_ip}%'"
                    cursor.execute(query)
                    print(f"Updated {table}.{col}: {cursor.rowcount} rows affected.")
                else:
                    print(f"Skipping {table}.{col}: Column not found.")
            except Exception as e:
                print(f"Error updating {table}.{col}: {e}")
                
        db.disconnect()
        print("IP Fix complete.")
    else:
        print("Failed to connect to DB")

if __name__ == "__main__":
    fix_ips()
