
import boto3
import os
import time
from botocore.config import Config
from dotenv import load_dotenv

# Load env vars
load_dotenv('/var/www/server_global/.env')

R2_ACCESS_KEY_ID = os.getenv('R2_ACCESS_KEY_ID')
R2_SECRET_ACCESS_KEY = os.getenv('R2_SECRET_ACCESS_KEY')
R2_BUCKET_NAME = os.getenv('R2_BUCKET_NAME')
R2_ENDPOINT_URL = os.getenv('R2_ENDPOINT_URL')

print(f"Testing connectivity to: {R2_ENDPOINT_URL}")
print(f"Bucket: {R2_BUCKET_NAME}")

try:
    client = boto3.client(
        's3',
        endpoint_url=R2_ENDPOINT_URL,
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        region_name='auto',
        config=Config(signature_version='s3v4', connect_timeout=10, read_timeout=10)
    )

    # 1. List Buckets (Simple auth check)
    print("Attempting to list buckets...")
    start = time.time()
    resp = client.list_buckets()
    print(f"List buckets success! Took {time.time() - start:.2f}s")
    
    # 2. Upload test
    print("Attempting to upload test file...")
    test_key = "test_connectivity_check.txt"
    start = time.time()
    client.put_object(
        Bucket=R2_BUCKET_NAME,
        Key=test_key,
        Body=b"Connectivity check successful!"
    )
    print(f"Upload success! Took {time.time() - start:.2f}s")
    
    print("Test passed.")

except Exception as e:
    print(f"\nTEST FAILED: {e}")
