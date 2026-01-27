from database import Database

db = Database()
if db.connect():
    print("Recent playback_history records:")
    res = db.execute_query("SELECT user_id, book_id, playlist_item_id, played_seconds FROM playback_history ORDER BY id DESC LIMIT 10")
    if res:
        for r in res:
            track_id = r['playlist_item_id'] if r['playlist_item_id'] else 'NULL'
            print(f"  User: {r['user_id']}, Book: {r['book_id']}, Track: {track_id}, Position: {r['played_seconds']}s")
    else:
        print("  No records found")
    db.disconnect()
