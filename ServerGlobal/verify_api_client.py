import urllib.request
import json
import ssl

url = "https://echo.velorus.ba/reels?user_id=50&limit=5"
headers = {
    "X-App-Source": "Echo_Secured_9xQ2zP5mL8kR4wN1vJ7",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

try:
    req = urllib.request.Request(url, headers=headers)
    
    # Ignore SSL errors if any (self-signed dev certs?)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    with urllib.request.urlopen(req, context=ctx) as response:
        if response.status == 200:
            data = json.loads(response.read().decode())
            print(json.dumps(data, indent=2))
        else:
            print(f"Error: {response.status} - {response.read().decode()}")
except Exception as e:
    print(f"Request failed: {e}")
