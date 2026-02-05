import os
import requests

# CONFIGURATION
# ------------------------------------------------------------------
API_URL = "https://echo.velorus.ba"
ADMIN_EMAIL = "bojanpejic97@gmail.com"
LOGIN_PASSWORD = "YOUR_ADMIN_PASSWORD_HERE" # You'll need to implement login or hardcode a token
SECRET_HEADER = "Echo_Secured_9xQ2zP5mL8kR4wN1vJ7"

# 1. Login to get Token
def login():
    # Note: You might want to implement a simpler "API Key" for admin scripts later
    # For now, we simulate a login or just paste a valid token here
    print("Please paste a valid Admin Bearer Token (from Postman/App):")
    return input("Token: ").strip()

# 2. Upload Function
def upload_book(folder_path, category_id, token):
    files = []
    # Find audio files
    processed_files = []
    for f in os.listdir(folder_path):
        if f.lower().endswith(('.mp3', '.wav', '.m4a')):
            full_path = os.path.join(folder_path, f)
            files.append(('audio', (f, open(full_path, 'rb'), 'audio/mpeg')))
            processed_files.append(full_path)
    
    if not files:
        print(f"No audio found in {folder_path}")
        return

    # Metadata (You would parse this from a JSON file or folder name)
    data = {
        'title': os.path.basename(folder_path), # Use folder name as title
        'author': "Various",
        'category_id': category_id,
        'user_id': 1, # Admin ID
        'is_premium': '1'
    }

    headers = {
        'Authorization': f'Bearer {token}',
        'X-App-Source': SECRET_HEADER
    }

    print(f"Uploading {data['title']}...")
    try:
        response = requests.post(
            f"{API_URL}/upload_book",
            data=data,
            files=files,
            headers=headers
        )
        
        if response.status_code == 200:
            print(f"SUCCESS: {response.json()}")
        else:
            print(f"FAILED: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        # Close file handles
        for _, (name, f_obj, _) in files:
            f_obj.close()

# 3. Main Loop
if __name__ == "__main__":
    # Example usage:
    # ROOT_FOLDER = "./my_books_to_upload"
    # CATEGORY_ID = 5 
    
    token = login()
    
    # Walk through folders...
    # for directory in os.listdir(ROOT_FOLDER):
    #    upload_book(os.path.join(ROOT_FOLDER, directory), CATEGORY_ID, token)
    
    print("Script template ready. Edit me to connect to your folders!")
