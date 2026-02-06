
import sys
sys.path.append('/var/www/server_global')
from dotenv import load_dotenv
load_dotenv('/var/www/server_global/.env')
from database import Database
import json

db = Database()
if not db.connect():
    print("DB Connection Failed")
    sys.exit(1)

print("--- Step 1: Fetch Books (Reels Logic) ---")
books_query = """
    SELECT b.id, b.title, b.audio_path
    FROM books b
    ORDER BY b.id DESC
    LIMIT 5 OFFSET 0
"""
books = db.execute_query(books_query)
print(f"Fetched {len(books) if books else 0} books")

if not books:
    sys.exit(0)

book_ids = [b['id'] for b in books]
print(f"Book IDs: {book_ids}")
print(f"Audio Paths: {[b['audio_path'] for b in books]}")

print("\n--- Step 2: Fetch Playlist Items (Optimized Logic) ---")
placeholders = ','.join(['%s'] * len(book_ids))
sql = f"""
    SELECT id, book_id, file_path, track_order
    FROM playlist_items
    WHERE book_id IN ({placeholders})
    ORDER BY book_id, track_order
"""
print(f"SQL: {sql}")

try:
    items = db.execute_query(sql, tuple(book_ids))
    print(f"Items Fetched: {len(items) if items else 0}")
    if items:
        # Check distribution
        counts = {}
        for item in items:
            bid = item['book_id']
            counts[bid] = counts.get(bid, 0) + 1
        print(f"Items per book: {counts}")
    else:
        print("!!! NO ITEMS RETURNED !!!")

except Exception as e:
    print(f"SQL Error: {e}")

db.disconnect()
