
from r2_storage import get_r2_client, R2_BUCKET_NAME
from dotenv import load_dotenv
load_dotenv()
try:
    c = get_r2_client()
    objs = c.list_objects_v2(Bucket=R2_BUCKET_NAME, MaxKeys=1)
    if 'Contents' in objs:
        print(objs['Contents'][0]['Key'])
    else:
        print("EMPTY")
except Exception as e:
    print(str(e))
