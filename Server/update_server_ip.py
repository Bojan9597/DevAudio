import socket
import mysql.connector
from database import Database
import re

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
        ("playlist_items", "audio_path"),
        ("users", "profile_picture")
    ] # Added comma here just in case? No, syntax is fine.

    # We want to find OLD IPs. 
    # Strategy: Find any URL like http://X.X.X.X:5000
    # and if X.X.X.X != current_ip, update it.
    
    # Regex to extract Base URL IP from DB is hard in pure SQL usually.
    # So we fetch sample rows to find candidate "Old IPs".
    
    found_old_ips = set()
    
    for table, col in targets:
        try:
            # Get distinct IPs used in this column
            # We look for simple http value
            query = f"SELECT {col} FROM {table} WHERE {col} LIKE 'http://%:5000%'"
            cursor.execute(query)
            results = cursor.fetchall()
            
            for (val,) in results:
                if val:
                    # Extract IP regex
                    match = re.search(r'http://([^:]+):5000', val)
                    if match:
                        ip_in_db = match.group(1)
                        if ip_in_db != current_ip:
                            found_old_ips.add(ip_in_db)
        except Exception as e:
            # Column might not exist or empty
            print(f"Skipping check for {table}.{col}: {e}")

    if not found_old_ips:
        print(f"No mismatched IPs found. All URLs seem to match {current_ip} (or table is empty).")
    else:
        print(f"Found mismatching IPs in database: {found_old_ips}")
        print(f"Updating all to '{current_ip}'...")
        
        for old_ip in found_old_ips:
            for table, col in targets:
                try:
                    # Run Update
                    # REPLACE(str, from_str, to_str)
                    query = f"UPDATE {table} SET {col} = REPLACE({col}, '{old_ip}', '{current_ip}') WHERE {col} LIKE '%{old_ip}%'"
                    cursor.execute(query)
                    if cursor.rowcount > 0:
                        print(f" - Updated {cursor.rowcount} rows in {table}.{col} (Replaced {old_ip})")
                except Exception as e:
                    print(f"   Error updating {table}.{col}: {e}")

    db.disconnect()
    print("---------------------------------------------------")
    print(f"Database IP Update Check Complete. (Target: {current_ip})")
    
    # Also update Flutter Client Configuration
    update_flutter_client(current_ip)

def update_flutter_client(current_ip):
    # Path to api_constants.dart
    # Assuming relative path from Server/ directory
    dart_path = "../hello_flutter/lib/utils/api_constants.dart"
    
    try:
        with open(dart_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Regex to find: static const String baseUrl = 'http://X.X.X.X:5000';
        # We replace the IP
        new_content = re.sub(
            r"(static const String baseUrl = 'http://)[^:]+(:5000';)",
            f"\\g<1>{current_ip}\\g<2>",
            content
        )
        
        # Also update the Android specific line
        # return 'http://10.X.X.X:5000';
        new_content = re.sub(
            r"(return 'http://)[^:]+(:5000';)",
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
