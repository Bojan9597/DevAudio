"""
Cloudflare R2 Storage Module
Handles uploading files to R2 (private bucket) and generating pre-signed URLs
for temporary access. Falls back to local storage if R2 is not configured.
"""
import os
import boto3
from boto3.s3.transfer import TransferConfig
from botocore.config import Config
from botocore.exceptions import ClientError, NoCredentialsError, BotoCoreError
from dotenv import load_dotenv
import mimetypes
import time
import logging

# Set up logging for R2 operations
logging.basicConfig(level=logging.INFO)
r2_logger = logging.getLogger('R2')

load_dotenv()

# R2 Configuration
R2_ACCESS_KEY_ID = os.getenv('R2_ACCESS_KEY_ID')
R2_SECRET_ACCESS_KEY = os.getenv('R2_SECRET_ACCESS_KEY')
R2_BUCKET_NAME = os.getenv('R2_BUCKET_NAME', 'devaudio')
R2_ENDPOINT_URL = os.getenv('R2_ENDPOINT_URL')

# Pre-signed URL expiry in seconds (default 2 hours)
R2_URL_EXPIRY = int(os.getenv('R2_URL_EXPIRY', '7200'))

# Prefix to identify R2 keys stored in DB (not a real URL, just a marker)
R2_KEY_PREFIX = "r2://"

# R2 Public Domain (Custom Domain for Caching)
R2_PUBLIC_DOMAIN = os.getenv('R2_PUBLIC_DOMAIN')

# Check if R2 is configured
R2_ENABLED = all([R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT_URL])

if R2_ENABLED:
    print(f"[R2] Cloudflare R2 storage enabled. Bucket: {R2_BUCKET_NAME}")
    if R2_PUBLIC_DOMAIN:
        print(f"[R2] Using Public Domain: {R2_PUBLIC_DOMAIN}")
    else:
        print(f"[R2] Pre-signed URL expiry: {R2_URL_EXPIRY}s ({R2_URL_EXPIRY // 3600}h)")
else:
    print("[R2] WARNING: R2 not configured. Uploads will use local storage.")


def get_r2_client():
    """Get a boto3 S3 client configured for Cloudflare R2 with timeouts."""
    return boto3.client(
        's3',
        endpoint_url=R2_ENDPOINT_URL,
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        region_name='us-east-1', # R2 requires us-east-1 for signature compatibility
        config=Config(
            signature_version='s3v4',
            connect_timeout=10,              # 10s connection timeout
            read_timeout=30,                 # 30s read timeout (for slower uploads)
            retries={'max_attempts': 2, 'mode': 'adaptive'},  # Retry once on failure
        ),
    )


def guess_content_type(filename):
    """Guess content type from filename."""
    content_type, _ = mimetypes.guess_type(filename)
    if content_type:
        return content_type
    ext = os.path.splitext(filename)[1].lower()
    type_map = {
        '.mp3': 'audio/mpeg',
        '.wav': 'audio/wav',
        '.m4a': 'audio/mp4',
        '.flac': 'audio/flac',
        '.ogg': 'audio/ogg',
        '.opus': 'audio/opus',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.pdf': 'application/pdf',
    }
    return type_map.get(ext, 'application/octet-stream')


def upload_fileobj_to_r2(file_obj, r2_key, content_type=None):
    """
    Upload a file-like object to R2 using a subprocess worker.
    This bypasses Gevent/Boto3 compatibility issues completely.

    Args:
        file_obj: File-like object (e.g. from request.files or open())
        r2_key: The key (path) in the R2 bucket
        content_type: MIME type. If None, guessed from r2_key.

    Returns:
        R2 key reference string (r2://key) on success, None on failure.
    """
    if not R2_ENABLED:
        r2_logger.warning("[R2] R2 not configured, falling back to local storage")
        return None

    if content_type is None:
        content_type = guess_content_type(r2_key)

    start_time = time.time()
    r2_logger.info(f"[R2] Starting subprocess upload to {r2_key}")

    import subprocess
    import tempfile
    import shutil
    import sys

    # Save stream to temp file first (needed for subprocess)
    try:
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            if hasattr(file_obj, 'read'):
                shutil.copyfileobj(file_obj, tmp)
            else:
                tmp.write(file_obj)
            tmp_path = tmp.name

        # Run worker script
        # Using the same python interpreter as the parent process
        worker_path = os.path.join(os.path.dirname(__file__), 'r2_worker.py')
        
        result = subprocess.run(
            [sys.executable, worker_path, tmp_path, r2_key, content_type],
            capture_output=True,
            text=True,
            timeout=120  # Explicit subprocess timeout preventing infinite hang
        )

        # Cleanup temp file
        try:
            os.unlink(tmp_path)
        except:
            pass

        if result.returncode == 0 and "SUCCESS" in result.stdout:
            elapsed = time.time() - start_time
            r2_logger.info(f"[R2] Subprocess upload success in {elapsed:.2f}s")
            return f"{R2_KEY_PREFIX}{r2_key}"
        else:
            r2_logger.error(f"[R2] Worker failed: {result.stderr} {result.stdout}")
            return None

    except Exception as e:
        elapsed = time.time() - start_time
        r2_logger.error(f"[R2] Unexpected error in upload wrapper: {e}")
        return None


def upload_local_file_to_r2(local_path, r2_key, content_type=None):
    """
    Upload a local file to R2.

    Args:
        local_path: Path to local file
        r2_key: The key (path) in the R2 bucket
        content_type: MIME type. If None, guessed from filename.

    Returns:
        R2 key reference string (r2://key) on success, None on failure.
    """
    if not R2_ENABLED:
        return None

    try:
        with open(local_path, 'rb') as f:
            return upload_fileobj_to_r2(f, r2_key, content_type)
    except FileNotFoundError:
        print(f"[R2] Local file not found: {local_path}")
        return None


def generate_presigned_url(r2_key, expiry=None):
    """
    Generate a pre-signed URL for temporary access to a private R2 object.

    Args:
        r2_key: The key (path) in the R2 bucket
        expiry: URL expiry in seconds. Defaults to R2_URL_EXPIRY.

    Returns:
        Pre-signed URL string, or None on failure.
    """
    if not R2_ENABLED:
        return None

    if expiry is None:
        expiry = R2_URL_EXPIRY

    try:
        client = get_r2_client()
        url = client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': R2_BUCKET_NAME,
                'Key': r2_key,
            },
            ExpiresIn=expiry,
        )
        return url
    except Exception as e:
        print(f"[R2] Pre-signed URL generation failed for {r2_key}: {e}")
        return None


def is_r2_ref(path):
    """Check if a stored path is an R2 reference (r2://key)."""
    return path is not None and path.startswith(R2_KEY_PREFIX)


def get_r2_key(r2_ref):
    """Extract the R2 key from an R2 reference string (r2://key -> key)."""
    if r2_ref and r2_ref.startswith(R2_KEY_PREFIX):
        return r2_ref[len(R2_KEY_PREFIX):]
    return r2_ref


def resolve_url(stored_path, base_url=None):
    """
    Resolve a stored path to a usable URL.
    - If it's an R2 reference (r2://...), generate a pre-signed URL.
    - If it's already an http URL, return as-is.
    - If it's a relative path, prepend base_url.

    Args:
        stored_path: The path stored in the database.
        base_url: The BASE_URL for local files.

    Returns:
        A usable URL string, or None.
    """
    if not stored_path:
        return None

    if is_r2_ref(stored_path):
        r2_key = get_r2_key(stored_path)
        
        # 1. Prefer Public Domain (Cache Friendly)
        if R2_PUBLIC_DOMAIN:
            return f"{R2_PUBLIC_DOMAIN}/{r2_key}"
            
        # 2. Fallback to Pre-signed URL (Private)
        url = generate_presigned_url(r2_key)
        if url:
            return url
        # Fallback: can't generate URL
        print(f"[R2] WARNING: Could not generate pre-signed URL for {r2_key}")
        return None

    if stored_path.startswith('http'):
        return stored_path

    # Relative path - prepend base_url
    if base_url:
        return f"{base_url}{stored_path}"

    return stored_path


def is_r2_enabled():
    """Check if R2 storage is configured and enabled."""
    return R2_ENABLED
