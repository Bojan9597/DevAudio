from database import Database

db = Database()
if db.connect():
    print("Playback history records:")
    res = db.execute_query("""
        SELECT ph.*, uct.id as completed_id
        FROM playback_history ph
        LEFT JOIN user_completed_tracks uct ON ph.user_id = uct.user_id AND ph.playlist_item_id = uct.track_id
        ORDER BY ph.id DESC 
        LIMIT 10
    """)
    if res:
        for r in res:
            track = r['playlist_item_id'] if r['playlist_item_id'] else 'NULL'
            completed = "COMPLETED" if r['completed_id'] else "in-progress"
            print(f"  User:{r['user_id']} Book:{r['book_id']} Track:{track} Pos:{r['played_seconds']}s [{completed}]")
    else:
        print("  No records")
    
    print("\nCompleted tracks:")
    res2 = db.execute_query("SELECT * FROM user_completed_tracks ORDER BY id DESC LIMIT 5")
    if res2:
        for r in res2:
            print(f"  User:{r['user_id']} Track:{r['track_id']}")
    else:
        print("  No completed tracks")
    
    db.disconnect()
