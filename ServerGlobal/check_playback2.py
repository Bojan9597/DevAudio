from database import Database

db = Database()
if db.connect():
    print("Recent playback_history:")
    res = db.execute_query("SELECT * FROM playback_history ORDER BY id DESC LIMIT 10")
    if res:
        for r in res:
            track = r['playlist_item_id'] if r['playlist_item_id'] else 'NULL'
            print(f"  ID:{r['id']} User:{r['user_id']} Book:{r['book_id']} Track:{track} Pos:{r['played_seconds']}s Time:{r['end_time']}")
    else:
        print("  No records")
    
    print("\nChecking unique constraint:")
    res2 = db.execute_query("""
        SELECT CONSTRAINT_NAME 
        FROM information_schema.TABLE_CONSTRAINTS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'playback_history' 
        AND CONSTRAINT_TYPE = 'UNIQUE'
    """)
    if res2:
        for r in res2:
            print(f"  Constraint: {r['CONSTRAINT_NAME']}")
    else:
        print("  No unique constraints found")
    
    db.disconnect()
