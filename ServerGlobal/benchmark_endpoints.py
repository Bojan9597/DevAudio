
import sys
import os
sys.path.append('/var/www/server_global')

import time
import concurrent.futures
import urllib.request
import urllib.error
import ssl
from jwt_config import generate_access_token

# Configuration
USER_ID = 45
CONCURRENCY = 20
REQUESTS_PER_ENDPOINT = 100
BASE_URL = "https://127.0.0.1"

# SSL Context (Ignore localhost cert)
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# Generate Auth Token
print("Generating benchmark token...")
token = generate_access_token(user_id=USER_ID, session_id='benchmark')
headers = {
    'Host': 'echo.velorus.ba',
    'Authorization': f'Bearer {token}'
}

ENDPOINTS = [
    "/categories",
    "/discover",
    "/reels?user_id=45&limit=5",
    "/books"
]

results = []

def load_request(url):
    try:
        start = time.time()
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10, context=ctx) as response:
             response.read(1024) 
             status = response.getcode()
        return time.time() - start, status
    except urllib.error.HTTPError as e:
        return time.time() - start, e.code
    except Exception as e:
        return 0, 0

print(f"{'ENDPOINT':<30} | {'RPS':<10} | {'AVG LATENCY (ms)':<18} | {'ERRORS':<10}")
print("-" * 75)

for endpoint in ENDPOINTS:
    url = BASE_URL + endpoint
    times = []
    errors = 0
    
    start_bench = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = [executor.submit(load_request, url) for _ in range(REQUESTS_PER_ENDPOINT)]
        for future in concurrent.futures.as_completed(futures):
            duration, status = future.result()
            if status != 200:
                if status == 0: # Exception
                     errors += 1
                # 4xx/5xx are valid responses for benchmark speed, but strictly speaking errors
                # We count valid HTTP responses as success for speed test? 
                # Let's count non-200 as potentially error
                pass  
            
            if duration > 0:
                times.append(duration)

    total_time = time.time() - start_bench
    rps = REQUESTS_PER_ENDPOINT / total_time
    avg_latency = (sum(times) / len(times) * 1000) if times else 0
    
    print(f"{endpoint:<30} | {rps:<10.2f} | {avg_latency:<18.2f} | {errors:<10}")

