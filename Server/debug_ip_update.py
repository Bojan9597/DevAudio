import re
import os
import socket

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception as e:
        print(f"Error: {e}")
        return "127.0.0.1"

def update_flutter_client(current_ip):
    dart_path = "../hello_flutter/lib/utils/api_constants.dart"
    print(f"Targeting: {os.path.abspath(dart_path)}")
    
    try:
        with open(dart_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        print("Original Content (snippet):")
        print(content[:200]) # Show first 200 chars
            
        current_ip = "192.168.100.15" # Force check with what we think is real IP locally
        
        # Regex 1
        new_content = re.sub(
            r"(static const String baseUrl = 'http://)[^:]+(:5000';)",
            f"\\g<1>{current_ip}\\g<2>",
            content
        )
        
        # Regex 2
        new_content = re.sub(
            r"(return 'http://)(?!127\.0\.0\.1)(?:[0-9]{1,3}\.){3}[0-9]{1,3}(:5000';)",
            f"\\g<1>{current_ip}\\g<2>",
            new_content
        )
        
        if new_content != content:
            print(f"MATCH FOUND! Updating to {current_ip}")
            with open(dart_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
        else:
            print("NO MATCH FOUND. Regex might be wrong or content already matches.")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    update_flutter_client("192.168.100.15")
