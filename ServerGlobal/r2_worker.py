
import os
import sys
import boto3
from botocore.config import Config
from dotenv import load_dotenv

# Explicitly load env vars from server location
load_dotenv('/var/www/server_global/.env')

def upload_worker(file_path, r2_key, content_type):
    """
    Standalone upload worker.
    """
    R2_ACCESS_KEY_ID = os.getenv('R2_ACCESS_KEY_ID')
    R2_SECRET_ACCESS_KEY = os.getenv('R2_SECRET_ACCESS_KEY')
    R2_BUCKET_NAME = os.getenv('R2_BUCKET_NAME')
    R2_ENDPOINT_URL = os.getenv('R2_ENDPOINT_URL')
    
    if not all([R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_ENDPOINT_URL]):
        print("ERROR: Missing configuration")
        sys.exit(1)

    try:
        # Standard Boto3 client (No Gevent patching here!)
        client = boto3.client(
            's3',
            endpoint_url=R2_ENDPOINT_URL,
            aws_access_key_id=R2_ACCESS_KEY_ID,
            aws_secret_access_key=R2_SECRET_ACCESS_KEY,
            region_name='auto',
            config=Config(signature_version='s3v4', connect_timeout=30, read_timeout=120)
        )

        with open(file_path, 'rb') as f:
            client.upload_fileobj(
                f,
                R2_BUCKET_NAME, 
                r2_key,
                ExtraArgs={'ContentType': content_type}
            )
        
        print("SUCCESS")
        sys.exit(0)
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python3 r2_worker.py <file_path> <r2_key> <content_type>")
        sys.exit(1)
        
    upload_worker(sys.argv[1], sys.argv[2], sys.argv[3])
