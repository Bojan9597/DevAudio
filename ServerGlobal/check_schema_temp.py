from database import Database

db = Database()
if db.connect():
    try:
        print("=== PLAYBACK_HISTORY TABLE ===")
        cursor = db.connection.cursor(dictionary=True)
        cursor.execute("SHOW COLUMNS FROM playback_history")
        columns = cursor.fetchall()
        for col in columns:
            print(f"{col['Field']}: {col['Type']} {col['Null']} {col['Key']} {col['Default']}")
        cursor.close()
        
        print("\n=== PLAYLIST_ITEMS TABLE ===")
        cursor = db.connection.cursor(dictionary=True)
        cursor.execute("SHOW COLUMNS FROM playlist_items")
        columns = cursor.fetchall()
        for col in columns:
            print(f"{col['Field']}: {col['Type']} {col['Null']} {col['Key']} {col['Default']}")
        cursor.close()
        
    finally:
        db.disconnect()
