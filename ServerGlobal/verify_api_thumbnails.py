import requests
import json

try:
    response = requests.get('http://127.0.0.1:5000/books?page=1&limit=5')
    if response.status_code == 200:
        books = response.json()
        print(f"Found {len(books)} books.")
        for book in books:
            print(f"ID: {book.get('id')}")
            print(f"  Cover: {book.get('coverUrl')}")
            print(f"  Thumb: {book.get('coverUrlThumbnail')}")
            
            thumb = book.get('coverUrlThumbnail')
            if thumb and 'thumbnails' in thumb:
                print("  ✅ Thumbnail URL looks correct")
            else:
                print("  ❌ Thumbnail URL missing or incorrect")
    else:
        print(f"Error: Status code {response.status_code}")
except Exception as e:
    print(f"Error: {e}")
