
from r2_storage import upload_fileobj_to_r2
from io import BytesIO
import os
from dotenv import load_dotenv
load_dotenv()

try:
    f = BytesIO(b"Hello World")
    print("Uploading test.txt...")
    res = upload_fileobj_to_r2(f, "test.txt", "text/plain")
    print(f"Result: {res}")
except Exception as e:
    print(f"Error: {e}")
