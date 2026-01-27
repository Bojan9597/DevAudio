import os
import shutil
import re
from database import Database

def sanitize_filename(name):
    s = re.sub(r'[^\w\s-]', '', name).strip().lower()
    return re.sub(r'[-\s]+', '_', s) + ".mp3"

def reorganize_and_update():
    # Paths
    # Script is in Server/
    # Source: ../static/AudioBooks
    # Dest: static/AudioBooks
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    source_dir = os.path.join(base_dir, '..', 'static', 'AudioBooks')
    dest_dir = os.path.join(base_dir, 'static', 'AudioBooks')
    
    if not os.path.exists(source_dir):
        print(f"Source directory not found: {source_dir}")
        return

    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
        print(f"Created destination directory: {dest_dir}")

    # Get source files
    files = sorted([f for f in os.listdir(source_dir) if f.endswith('.mp3')])
    print(f"Found {len(files)} files in source.")

    # DB Connection
    db = Database()
    if not db.connect():
        print("DB Connection failed")
        return

    # Get Books
    books = db.execute_query("SELECT id, title FROM books ORDER BY id ASC LIMIT 10")
    
    if len(files) < len(books):
        print("Warning: More books than files. Some books won't have audio.")
    
    updated_count = 0
    
    for i, book in enumerate(books):
        if i >= len(files):
            break
            
        file_name = files[i]
        old_path = os.path.join(source_dir, file_name)
        
        # New name based on title
        new_name = sanitize_filename(book['title'])
        new_path = os.path.join(dest_dir, new_name)
        
        # Copy/Move file
        print(f"Moving {file_name} -> {new_name}")
        shutil.copy2(old_path, new_path) # Using copy to be safe, can change to move
        
        # Update URL
        # 10.0.2.2 is for Android Emulator to localhost. 
        # If running on Web, localhost is fine.
        # But let's stick to 10.0.2.2 as general 'emulator accessible' or just 'http://localhost:5000' for general
        # The previous script used 10.0.2.2.
        
        new_url = f"https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/{new_name}"
        
        query = "UPDATE books SET audio_path = %s WHERE id = %s"
        db.execute_query(query, (new_url, book['id']))
        updated_count += 1
        
    db.disconnect()
    print(f"Updated {updated_count} books.")

if __name__ == "__main__":
    reorganize_and_update()
