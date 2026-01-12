import mysql.connector
import os
import json
import datetime

def default_serializer(obj):
    if isinstance(obj, (datetime.date, datetime.datetime)):
        return obj.isoformat()
    return str(obj)

try:
    conn = mysql.connector.connect(
        host="localhost",
        database="audiobooks",
        user="root",
        password="Pijanista123!"
    )
    cursor = conn.cursor(dictionary=True)
    
    # Get last 5 books
    cursor.execute("SELECT id, title, audio_path, posted_by_user_id, price FROM books ORDER BY id DESC LIMIT 5")
    books = cursor.fetchall()
    
    print("\n--- Last 5 Books ---")
    for b in books:
        print(f"ID: {b['id']}, Title: {b['title']}, Audio: {b['audio_path']}, User: {b['posted_by_user_id']}")
        
        # Check file
        full_path = os.path.join("static", "audiobooks", b['audio_path'])
        exists = os.path.exists(full_path)
        print(f"   -> File: {full_path} | Exists: {exists}")
        if not exists:
             # Try listing directory to see what IS there
             print("   -> Listing static/audiobooks (first 5):")
             try:
                 print(os.listdir("static/audiobooks")[:5])
             except:
                 print("Directory not found")

    cursor.close()
    conn.close()

except Exception as e:
    print(f"Error: {e}")
