
import time
import concurrent.futures
import sys
import urllib.request
import urllib.error
import ssl

# Target localhost HTTPS to bypass network latency but test full Nginx+Gunicorn stack
URL = "https://127.0.0.1/books" 
CONCURRENCY = 50
TOTAL_REQUESTS = 500

# Ignore SSL certificate errors for localhost testing
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

print(f"--- LOAD TEST STARTING ---")
print(f"Target: {URL} (Host: echo.velorus.ba)")
print(f"Concurrency: {CONCURRENCY}")
print(f"Total Requests: {TOTAL_REQUESTS}")

def load_request(i):
    try:
        start = time.time()
        # Inject Host header so Nginx routes it correctly
        req = urllib.request.Request(URL, headers={'Host': 'echo.velorus.ba'})
        
        # Use simple timeout and read a bit of data to force IO
        with urllib.request.urlopen(req, timeout=5, context=ctx) as response:
             response.read(1024) # Ensure we actually read data
             status_code = response.getcode()
        
        duration = time.time() - start
        return {'status': status_code, 'duration': duration, 'error': None}
    except urllib.error.HTTPError as e:
        duration = time.time() - start
        return {'status': e.code, 'duration': duration, 'error': None} # HTTP errors are still responses
    except Exception as e:
        return {'status': 0, 'duration': 0, 'error': str(e)}

start_time = time.time()
succeeded = 0
failed = 0
total_latency = 0

with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
    futures = [executor.submit(load_request, i) for i in range(TOTAL_REQUESTS)]
    for future in concurrent.futures.as_completed(futures):
        res = future.result()
        if res['error']:
            if failed == 0:
                print(f"DEBUG: First Error: {res['error']}")
            failed += 1
        else:
            succeeded += 1
            total_latency += res['duration']

end_time = time.time()
total_duration = end_time - start_time
rps = TOTAL_REQUESTS / total_duration
avg_latency = (total_latency / succeeded) * 1000 if succeeded else 0

print(f"\n--- RESULTS ---")
print(f"Time Taken: {total_duration:.2f}s")
print(f"Requests Per Second (RPS): {rps:.2f}")
print(f"Average Latency: {avg_latency:.2f}ms")
print(f"Successful: {succeeded}")
print(f"Failed: {failed}")
