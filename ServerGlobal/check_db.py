from database import Database
from r2_storage import resolve_url
import os

def check():
    db = Database()
    if not db.connect():
        print("DB fail")
        return

    print("Checking 'cover_image_path' in DB:")
    rows = db.execute_query("SELECT id, title, cover_image_path FROM books ORDER BY created_at DESC LIMIT 5")
    for r in rows:
        print(f"ID {r['id']}: {r['cover_image_path']}")
        # diverse check
        # try resolving with assumption
        url = resolve_url(r['cover_image_path'], base_url="https://folks-cant-decide-on-a-base-url.com")
        print(f" -> Resolved: {url}")
        
        if url and url.startswith("http"):
             import subprocess
             try:
                 # Check if URL is accessible
                 res = subprocess.run(["curl", "-I", "-s", "-o", "/dev/null", "-w", "%{http_code}", url], capture_output=True, text=True)
                 print(f" -> Public URL ({url}) HTTP Status: {res.stdout.strip()}")
             except Exception as e:
                 print(f" -> Curl check failed: {e}")

        # DIAGNOSTIC 1: Check test.txt (known file from screenshot)
        test_url = "https://media.velorus.ba/test.txt"
        try:
             res2 = subprocess.run(["curl", "-I", "-s", "-o", "/dev/null", "-w", "%{http_code}", test_url], capture_output=True, text=True)
             print(f" -> Domain Diagnostic: {test_url} returned {res2.stdout.strip()}")
        except: pass

        # DIAGNOSTIC 2: Try Presigned URL (Verification of file existence)
        from r2_storage import generate_presigned_url, get_r2_key
        key = get_r2_key(r['cover_image_path'])
        signed = generate_presigned_url(key)
        if signed:
            print(f" -> Signed URL generated. Checking accessibility...")
            try:
                res3 = subprocess.run(["curl", "-I", "-s", "-o", "/dev/null", "-w", "%{http_code}", signed], capture_output=True, text=True)
                print(f" -> Signed URL Status: {res3.stdout.strip()}")
            except: pass
        # DIAGNOSTIC 3: List Objects (Deepest Verified Check)
        from r2_storage import get_r2_client
        import datetime
        print(f" -> Server Time (UTC): {datetime.datetime.utcnow()}")
        
        try:
             client = get_r2_client()
             print(f" -> Listing objects in 'BookCovers/'...")
             res = client.list_objects_v2(Bucket='echohistory', Prefix='BookCovers/', MaxKeys=5)
             if 'Contents' in res:
                 for obj in res['Contents']:
                     print(f"    - Found: {obj['Key']} (Size: {obj['Size']})")
                     
                     # Generate Signed URL for ONE found object to prove functionality
                     signed_found = generate_presigned_url(obj['Key'])
                     print(f"       -> Signed Check: {signed_found}")
                     try:
                         curl_res = subprocess.run(["curl", "-I", "-s", "-o", "/dev/null", "-w", "%{http_code}", signed_found], capture_output=True, text=True)
                         print(f"       -> HTTP: {curl_res.stdout.strip()}")
                     except: pass
                     break # Just check one
             else:
                 print("    - No objects found in BookCovers/ prefix. Check path or permissions.")
        except Exception as e:
             print(f" -> LIST OBJECTS FAILED: {e}")

        # DIAGNOSTIC 4: Bucket Policy (The Fixer)
        print(" -> Checking Bucket Policy...")
        try:
             policy = client.get_bucket_policy(Bucket='echohistory')
             print(f"    - Current Policy: {policy['Policy']}")
        except Exception as e:
             print(f"    - No Policy found or error: {e}")
             
             # User said "do it" -> Let's try to Apply Public Read Policy
             print("    -> Attempting to APPLY Public Read Policy...")
             import json
             public_policy = {
                 "Version": "2012-10-17",
                 "Statement": [
                     {
                         "Sid": "PublicRead",
                         "Effect": "Allow",
                         "Principal": "*",
                         "Action": ["s3:GetObject"],
                         "Resource": ["arn:aws:s3:::echohistory/*"]
                     }
                 ]
             }
             try:
                 client.put_bucket_policy(Bucket='echohistory', Policy=json.dumps(public_policy))
                 print("    -> SUCCESS: Public Read Policy Applied!")
                 
                 # Re-test Public URL
                 test_url = "https://media.velorus.ba/test.txt"
                 res_final = subprocess.run(["curl", "-I", "-s", "-o", "/dev/null", "-w", "%{http_code}", test_url], capture_output=True, text=True)
                 print(f"    -> Re-check {test_url}: {res_final.stdout.strip()}")
                 
             except Exception as pub_e:
                 print(f"    -> FAILED to apply policy: {pub_e}")

    db.disconnect()

if __name__ == "__main__":
    check()
