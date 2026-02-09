import requests
import json

url = "https://echo.velorus.ba/categories"
headers = {
    "X-App-Source": "Echo_Secured_9xQ2zP5mL8kR4wN1vJ7"
}

try:
    print(f"Fetching from {url}...")
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print("Success! Categories found:")
        # Print top-level categories to see if they match new ones
        for cat in data:
            print(f"- {cat.get('title')} (id: {cat.get('id')})")
            if 'children' in cat:
                for child in cat['children']:
                    print(f"  * {child.get('title')} (id: {child.get('id')})")
    else:
        print(f"Failed: {response.status_code}")
        print(response.text)

except Exception as e:
    print(f"Error: {e}")
