import socket
import mysql.connector
from database import Database
import re
import os

def get_local_ip():
    try:
        # Connect to an external server to determine the best local interface IP
        # We don't actually send data, just open a socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception as e:
        print(f"Error determining local IP: {e}")
        return "127.0.0.1"

def update_db_ip():
    current_ip = get_local_ip()
    print(f"Current Machine IP: {current_ip}")
    
    if current_ip == "127.0.0.1":
        print("Warning: Detected localhost. If you are on a LAN, this might not be what you want for mobile access.")
        
    db = Database()
    if not db.connect():
        print("Failed to connect to database.")
        return

    cursor = db.connection.cursor()
    
    # Tables and columns to check for URLs
    targets = [
        ("books", "audio_path"),
        ("books", "cover_image_path"),
        ("playlist_items", "file_path"), # Correction: playlist_items uses file_path not audio_path
        ("users", "profile_picture_url") # Correction: users uses profile_picture_url not profile_picture
    ]

    # ... (rest of logic) ...

def update_flutter_client(current_ip):
    # Path to api_constants.dart
    # Use absolute path relative to this script file to be CWD-independent
    base_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(base_dir) # Go up from Server/
    dart_path = os.path.join(project_root, "hello_flutter", "lib", "utils", "api_constants.dart")
    
    try:
        with open(dart_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Regex to find: static const String baseUrl = 'http://X.X.X.X:5000';
        new_content = re.sub(
            r"(static const String baseUrl = 'http://)[^:]+(:5000';)",
            f"\\g<1>{current_ip}\\g<2>",
            content
        )
        
        # Also update the Android specific line
        # return 'http://10.X.X.X:5000';
        # Regex: return 'http://<IP>:5000';
        # Be careful not to replace 127.0.0.1 unless needed, but usually we target the explicit IP line inside Platform.isAndroid check 
        # which currently is hardcoded to specific IP.
        
        # We target the line that looks like an IP (not 127.0.0.1 typically, unless the user manually set it)
        # But for 'return', it matches `return 'http://...`
        # Let's target lines containing IP pattern but exclude 127.0.0.1 if we want? 
        # Actually user wants "current ip".
        
        # Current file has: return 'http://10.177.190.89:5000';
        # We want to match that specific line structure.
        
        new_content = re.sub(
            r"(return 'http://)(?!127\.0\.0\.1)(?:[0-9]{1,3}\.){3}[0-9]{1,3}(:5000';)",
            f"\\g<1>{current_ip}\\g<2>",
            new_content
        )
        
        if new_content != content:
            with open(dart_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated Flutter Client Config (api_constants.dart) to {current_ip}")
        else:
            print(f"Flutter Client Config is already correct ({current_ip})")
            
    except Exception as e:
        print(f"Warning: Could not update Flutter config: {e}")

if __name__ == "__main__":
    update_db_ip()
