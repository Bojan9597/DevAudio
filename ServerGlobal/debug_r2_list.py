
import boto3
import os
from r2_storage import get_r2_client, R2_BUCKET_NAME

# Force load env to be sure
from dotenv import load_dotenv
load_dotenv()

try:
    client = get_r2_client()
    print(f"Listing bucket: {R2_BUCKET_NAME}")
    resp = client.list_objects_v2(Bucket=R2_BUCKET_NAME, MaxKeys=10)
    if 'Contents' in resp:
        for obj in resp['Contents']:
            print(f"KEY: {obj['Key']}")
    else:
        print("Bucket is empty or no contents returned.")
except Exception as e:
    print(f"Error: {e}")
