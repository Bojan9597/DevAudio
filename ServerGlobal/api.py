from gevent import monkey
monkey.patch_all()

from flask import Flask, jsonify, request, send_from_directory, Response
try:
    import orjson
    from flask.json.provider import DefaultJSONProvider
    from decimal import Decimal
    class OrjsonProvider(DefaultJSONProvider):
        def dumps(self, obj, **kwargs):
            return orjson.dumps(obj, default=self._default).decode()
        def loads(self, s, **kwargs):
            return orjson.loads(s)
        @staticmethod
        def _default(o):
            if isinstance(o, Decimal):
                return float(o)
            raise TypeError(f"Type is not JSON serializable: {type(o)}")
    _has_orjson = True
except ImportError:
    _has_orjson = False
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv
load_dotenv()
from werkzeug.utils import secure_filename
import os
import secrets
import base64
# from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
# from cryptography.hazmat.backends import default_backend
from werkzeug.security import generate_password_hash, check_password_hash
from database import Database
from badge_service import BadgeService
from mutagen import File as MutagenFile
from image_utils import ensure_thumbnail_exists, create_thumbnail
from r2_storage import upload_fileobj_to_r2, upload_local_file_to_r2, is_r2_enabled, is_r2_ref, get_r2_key, resolve_url, generate_presigned_url, R2_PUBLIC_DOMAIN
import tempfile
import shutil
import wave

import re
import datetime
import uuid
import secrets
import jwt as pyjwt
from jwt_config import generate_access_token, generate_refresh_token
from jwt_middleware import jwt_required, blacklist_token
import update_server_ip # Auto-update DB IP on startup
from session_manager import SessionManager
from cache_utils import cache, invalidate_user_cache

def generate_aes_key():
    """Generate a random 256-bit AES key and return as base64 string."""
    key = secrets.token_bytes(32)  # 256 bits
    return base64.b64encode(key).decode('utf-8')

def get_or_create_user_aes_key(user_id, db):
    """Get user's AES key, creating one if it doesn't exist."""
    query = "SELECT aes_key FROM users WHERE id = %s"
    result = db.execute_query(query, (user_id,))
    if result and result[0]['aes_key']:
        return result[0]['aes_key']

    # Generate new key
    new_key = generate_aes_key()
    update_query = "UPDATE users SET aes_key = %s WHERE id = %s"
    db.execute_query(update_query, (new_key, user_id))
    return new_key

def encrypt_file_data(data, key_base64):
    """Encrypt data using AES-CBC with PKCS7 padding. Returns IV + ciphertext."""
    # key = base64.b64decode(key_base64)
    # iv = secrets.token_bytes(16)

    # # PKCS7 padding
    # block_size = 16
    # padding_len = block_size - (len(data) % block_size)
    # padded_data = data + bytes([padding_len] * padding_len)

    # cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
    # encryptor = cipher.encryptor()
    # ciphertext = encryptor.update(padded_data) + encryptor.finalize()

    # return iv + ciphertext
    return data # Mock return to avoid crash if called, though it shouldn't be.

app = Flask(__name__)
if _has_orjson:
    app.json_provider_class = OrjsonProvider
    app.json = OrjsonProvider(app)
# Enable CORS for all routes (for web clients if any, but we are restricting now)
# We can keep CORS for development or specific origins, but the header check is stronger.
CORS(app)

# RATE LIMITING: 150 requests per minute per IP
# 150/min is a balanced limit for active users vs shared networks
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["150 per minute"],
    storage_uri="memory://",
)

# SECURITY: Shared Secret to allow only App Traffic
# This matches the Flutter App's "X-App-Source" header
APP_SOURCE_HEADER = "X-App-Source"
APP_SOURCE_VALUE = "Echo_Secured_9xQ2zP5mL8kR4wN1vJ7"

@app.before_request
def check_app_source():
    # Allow OPTIONS requests (CORS preflight) to pass without header
    if request.method == 'OPTIONS':
        return
        
    # Skip check for public static files if served via Flask (though Nginx usually handles them)
    if request.path.startswith('/static/'):
        return

    # Skip check for shared chapter web player (public links)
    if request.path.startswith('/shared/'):
        return

    # Enforce Secret Header
    client_secret = request.headers.get(APP_SOURCE_HEADER)
    if client_secret != APP_SOURCE_VALUE:
        # Log the attempt?
        # print(f"Unauthorized Access Attempt from {request.remote_addr}")
        return jsonify({"error": "Unauthorized: Invalid App Source"}), 403

# Base URL for external access (Ngrok or Local IP)
# Dynamically set based on current machine IP
# OR Hardcoded for Production Server
# current_ip = update_server_ip.get_local_ip()
# BASE_URL = f"http://{current_ip}:5000/" 
# BASE_URL = f"http://{current_ip}:5000/" 
BASE_URL = os.getenv('BASE_URL', "https://echo.velorus.ba/")
print(f"Server initialized with BASE_URL: {BASE_URL}")

# Auto-update Flutter Client Configuration (disabled for Prod)
# update_server_ip.update_flutter_client(current_ip)

session_manager = SessionManager()

# Admin email for upload functionality (preparation for Google Play subscription)
ADMIN_EMAIL = "bojanpejic97@gmail.com"

def is_admin_user(user_id, db):
    """Check if user is admin by email"""
    query = "SELECT email FROM users WHERE id = %s"
    result = db.execute_query(query, (user_id,))
    if result and result[0]['email'].lower() == ADMIN_EMAIL.lower():
        return True
    return False

def resolve_cover_urls(cover_path):
    """Resolve cover image path and thumbnail path, handling R2 refs, legacy URLs, and local paths.
    Returns (cover_url, thumbnail_url) tuple."""
    if not cover_path:
        return None, None

    cover_thumbnail_path = None

    if is_r2_ref(cover_path):
        # R2 reference (r2://BookCovers/filename)
        r2_key = get_r2_key(cover_path)
        
        if R2_PUBLIC_DOMAIN:
             # Use public domain for both cover and thumbnail
             cover_url = f"{R2_PUBLIC_DOMAIN}/{r2_key}"
             # Thumbnail key: BookCovers/filename -> BookCovers/thumbnails/filename
             thumb_key = r2_key.replace('BookCovers/', 'BookCovers/thumbnails/', 1)
             cover_thumbnail_path = f"{R2_PUBLIC_DOMAIN}/{thumb_key}"
             return cover_url, cover_thumbnail_path
        
        # Fallback to Pre-signed URLs
        cover_url = generate_presigned_url(r2_key)
        # Thumbnail was uploaded at upload time with key: BookCovers/thumbnails/filename
        thumb_key = r2_key.replace('BookCovers/', 'BookCovers/thumbnails/', 1)
        cover_thumbnail_path = generate_presigned_url(thumb_key)
        # Fallback: if thumbnail pre-sign fails, use the cover itself
        if not cover_thumbnail_path:
            cover_thumbnail_path = cover_url
        return cover_url, cover_thumbnail_path
    elif cover_path.startswith('http'):
        # Legacy absolute URL (e.g. BASE_URL + static/BookCovers/...)
        server_dir = os.path.dirname(os.path.abspath(__file__))
        filename = os.path.basename(cover_path.split('?')[0])
        thumbnail_local = os.path.join(server_dir, 'static', 'BookCovers', 'thumbnails', filename)
        if os.path.exists(thumbnail_local):
            cover_thumbnail_path = f"{BASE_URL}static/BookCovers/thumbnails/{filename}"
        else:
            source_path = os.path.join(server_dir, 'static', 'BookCovers', filename)
            if os.path.exists(source_path):
                ensure_thumbnail_exists(f"BookCovers/{filename}", os.path.join(server_dir, 'static'))
                cover_thumbnail_path = f"{BASE_URL}static/BookCovers/thumbnails/{filename}"
            else:
                cover_thumbnail_path = cover_path
    else:
        # Relative path (legacy local)
        if not cover_path.startswith('static/') and not cover_path.startswith('/static/'):
            cover_path = f"static/BookCovers/{cover_path}"
        if cover_path.startswith('/'):
            cover_path = cover_path[1:]
        server_dir = os.path.dirname(os.path.abspath(__file__))
        thumbnail_relative = ensure_thumbnail_exists(cover_path, os.path.join(server_dir, 'static'))
        cover_thumbnail_path = f"{BASE_URL}{thumbnail_relative}"
        cover_path = f"{BASE_URL}{cover_path}"

    return cover_path, cover_thumbnail_path

def resolve_stored_url(stored_path, path_prefix="AudioBooks"):
    """Resolve a stored path (r2:// ref, http URL, or relative) to a usable URL.
    Works for audio, PDF, profile pictures, and any other stored file path."""
    if not stored_path:
        return None
    if is_r2_ref(stored_path):
        return resolve_url(stored_path)
    if stored_path.startswith('http'):
        return stored_path
    # Relative path - check if we need to prepend static/ and prefix
    if not stored_path.startswith('static/') and not stored_path.startswith('/static/'):
        # potential cleaning of leading slash
        clean_stored = stored_path
        if clean_stored.startswith('/'):
            clean_stored = clean_stored[1:]
            
        # Check if it already starts with the prefix (to avoid double prefixing)
        # e.g. stored="profilePictures/foo.jpg", prefix="profilePictures"
        if clean_stored.startswith(path_prefix + '/'):
             stored_path = f"static/{clean_stored}"
        else:
             stored_path = f"static/{path_prefix}/{clean_stored}"

    if stored_path.startswith('/'):
        stored_path = stored_path[1:]
    return f"{BASE_URL}{stored_path}"

def is_subscriber(user_id, db):
    """Check if user has active subscription."""
    # Check cache (60s)
    cache_key = f"sub:{user_id}"
    cached = cache.get(cache_key)
    if cached is not None: return cached

    query = "SELECT status, end_date FROM subscriptions WHERE user_id = %s"
    result = db.execute_query(query, (user_id,))
    
    is_active = False
    if result and result[0]['status'] == 'active':
        end_date = result[0]['end_date']
        if end_date is None:  # Lifetime
            is_active = True
        else:
            is_active = end_date > datetime.datetime.utcnow()
            
    cache.set(cache_key, is_active, 60)
    return is_active

def has_book_access(user_id, book_id, db):
    """Check if user can access a specific book (via subscription or legacy purchase)."""
    if is_subscriber(user_id, db):
        return True
    # Fallback: check legacy purchase in user_books
    query = "SELECT id FROM user_books WHERE user_id = %s AND book_id = %s"
    result = db.execute_query(query, (user_id, book_id))
    return len(result) > 0 if result else False

@app.before_request
def log_request_info():
    print("="*50, flush=True)
    print(f"[DEBUG] Request: {request.method} {request.url}", flush=True)
    # print(f"[DEBUG] Headers: {request.headers}", flush=True) 
    if request.content_type == 'application/json':
        print(f"[DEBUG] JSON Body: {request.get_json(silent=True)}", flush=True)
    elif request.content_type and 'multipart/form-data' in request.content_type:
         print(f"[DEBUG] Form Data: {request.form}", flush=True)
         print(f"[DEBUG] Files: {request.files}", flush=True)

@app.after_request
def log_response_info(response):
    print(f"[DEBUG] Response Status: {response.status}", flush=True)
    print("="*50, flush=True)
    return response

print("--------------------------------------------------")
print("   DEBUG LOGGING MIDDLEWARE IS ACTIVE")
print("   Requests will be printed here...")
print("--------------------------------------------------")

# ... existing build_category_tree ...

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    confirm_password = data.get('confirm_password')

    if not all([name, email, password, confirm_password]):
        return jsonify({"error": "Missing fields"}), 400

    if password != confirm_password:
        return jsonify({"error": "Passwords do not match"}), 400

    # Password complexity check
    # At least 8 chars, 1 uppercase, 1 number, 1 special char
    if not re.match(r'''^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;"'<>,.?/\\|~-]).{8,}$''', password):
        return jsonify({
            "error": "Password must be at least 8 characters long and include an uppercase letter, a number, and a special character"
        }), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if user exists in main table
        check_query = "SELECT id FROM users WHERE email = %s"
        existing = db.execute_query(check_query, (email,))
        if existing:
            return jsonify({"error": "Email already registered"}), 409

        # Hash password
        hashed_pw = generate_password_hash(password)
        
        # Generate Verification Code
        import random
        verification_code = str(random.randint(100000, 999999))
        
        # Insert/Update pending user
        # Use INSERT ON CONFLICT for PostgreSQL (upsert)
        insert_query = """
            INSERT INTO pending_users (name, email, password_hash, verification_code) 
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (email) DO UPDATE SET 
                name = EXCLUDED.name, 
                password_hash = EXCLUDED.password_hash, 
                verification_code = EXCLUDED.verification_code,
                created_at = CURRENT_TIMESTAMP
        """
        cursor = db.connection.cursor()
        cursor.execute(insert_query, (name, email, hashed_pw, verification_code))
        db.connection.commit()
        cursor.close()
        
        # Mock sending email
        print("--------------------------------------------------")
        print(f"Verification code for {email}: {verification_code}")
        print("--------------------------------------------------")
        
        # Write to file for easier access
        with open("verification_code.txt", "w") as f:
            f.write(f"Verification code for {email}: {verification_code}")


        return jsonify({"message": "Verification code sent", "email": email}), 202


    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/verify-email', methods=['POST'])
def verify_email():
    data = request.get_json()
    email = data.get('email')
    code = data.get('code')
    
    if not all([email, code]):
        return jsonify({"error": "Missing email or code"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Check code in pending_users
        query = "SELECT * FROM pending_users WHERE email = %s"
        pending_users = db.execute_query(query, (email,))
        
        if not pending_users:
             return jsonify({"error": "Registration not found or already verified"}), 404
             
        pending_user = pending_users[0]
        if pending_user['verification_code'] == code:
            # Generate AES key for the new user
            aes_key = generate_aes_key()

            # Move to users table with AES key
            insert_query = "INSERT INTO users (name, email, password_hash, is_verified, aes_key) VALUES (%s, %s, %s, 1, %s) RETURNING id"
            cursor = db.connection.cursor()
            cursor.execute(insert_query, (pending_user['name'], pending_user['email'], pending_user['password_hash'], aes_key))
            user_id = cursor.fetchone()[0]
            db.connection.commit()

            # Delete from pending
            delete_query = "DELETE FROM pending_users WHERE email = %s"
            cursor.execute(delete_query, (email,))
            db.connection.commit()
            cursor.close()

            # Generate JWT tokens
            session_id = str(uuid.uuid4())
            access_token = generate_access_token(user_id, session_id)
            refresh_token = generate_refresh_token(user_id, session_id)

            # Store session (Single Session Policy)
            session_manager.store_session(user_id, session_id, refresh_token)

            # Return login data with AES key
            return jsonify({
                "message": "Verification successful",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": {
                    "id": user_id,
                    "name": pending_user['name'],
                    "email": pending_user['email'],
                    "profile_picture_url": None,
                    "aes_key": aes_key
                }
            }), 200
        else:
            return jsonify({"error": "Invalid verification code"}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not all([email, password]):
        return jsonify({"error": "Missing fields"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Fetch user
        query = "SELECT id, name, email, password_hash, profile_picture_url, is_verified FROM users WHERE email = %s"
        users = db.execute_query(query, (email,))
        
        if not users:
            return jsonify({"error": "Invalid credentials"}), 401
            
        user = users[0]
        
        if not user.get('is_verified', 1): # Default to 1 (True) for old users if column was just added
             # In our case we set default 0 but updated old ones to 1.
             # If user is not verified:
             if user['is_verified'] == 0:
                 return jsonify({"error": "Email not verified", "email": email}), 403
        
        # Verify password
        if check_password_hash(user['password_hash'], password):
            # Get or create AES key for user
            aes_key = get_or_create_user_aes_key(user['id'], db)

            # Generate JWT tokens
            session_id = str(uuid.uuid4())
            access_token = generate_access_token(user['id'], session_id)
            refresh_token = generate_refresh_token(user['id'], session_id)

            # Store session (Single Session Policy)
            session_manager.store_session(user['id'], session_id, refresh_token)

            return jsonify({
                "message": "Login successful",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": resolve_stored_url(user['profile_picture_url'], "profilePictures"),
                    "aes_key": aes_key
                }
            }), 200
        else:
            return jsonify({"error": "Invalid credentials"}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/change-password', methods=['POST'])
@jwt_required
def change_password():
    data = request.get_json()
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not all([user_id, current_password, new_password]):
        return jsonify({"error": "Missing fields"}), 400

    # Password complexity check for new password
    if not re.match(r'''^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;"'<>,.?/\\|~-]).{8,}$''', new_password):
        return jsonify({
            "error": "New password must be at least 8 characters long and include an uppercase letter, a number, and a special character"
        }), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Fetch user
        query = "SELECT password_hash FROM users WHERE id = %s"
        users = db.execute_query(query, (user_id,))
        
        if not users:
            return jsonify({"error": "User not found"}), 404
            
        user = users[0]
        
        # Verify current password
        if not check_password_hash(user['password_hash'], current_password):
            return jsonify({"error": "Incorrect current password"}), 401
            
        # Update with new password
        new_hash = generate_password_hash(new_password)
        update_query = "UPDATE users SET password_hash = %s WHERE id = %s"
        db.execute_query(update_query, (new_hash, user_id))
        
        return jsonify({"message": "Password updated successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/google-login', methods=['POST'])
def google_login():
    data = request.get_json()
    email = data.get('email')
    name = data.get('name')
    # google_id = data.get('google_id') # Optional, for syncing

    if not email:
        return jsonify({"error": "Email required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if user exists
        query = "SELECT id, name, email, profile_picture_url FROM users WHERE email = %s"
        users = db.execute_query(query, (email,))

        if users:
            # Login existing
            user = users[0]
            # Get or create AES key
            aes_key = get_or_create_user_aes_key(user['id'], db)

            session_id = str(uuid.uuid4())
            access_token = generate_access_token(user['id'], session_id)
            refresh_token = generate_refresh_token(user['id'], session_id)

            # Store session
            session_manager.store_session(user['id'], session_id, refresh_token)

            return jsonify({
                "message": "Login successful",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": resolve_stored_url(user['profile_picture_url'], "profilePictures"),
                    "aes_key": aes_key
                }
            }), 200
        else:
            # Register new user (with dummy password hash since it's Google auth)
            # Or make password nullable. For now, we set a placeholder hash.
            dummy_hash = generate_password_hash("google_auth_placeholder")
            aes_key = generate_aes_key()

            insert_query = "INSERT INTO users (name, email, password_hash, is_verified, aes_key) VALUES (%s, %s, %s, 1, %s) RETURNING id"
            cursor = db.connection.cursor()
            cursor.execute(insert_query, (name or "Google User", email, dummy_hash, aes_key))
            user_id = cursor.fetchone()[0]
            db.connection.commit()
            cursor.close()

            # Generate JWT tokens
            session_id = str(uuid.uuid4())
            access_token = generate_access_token(user_id, session_id)
            refresh_token = generate_refresh_token(user_id, session_id)

            # Store session
            session_manager.store_session(user_id, session_id, refresh_token)

            return jsonify({
                "message": "User registered via Google",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": {
                    "id": user_id,
                    "name": name,
                    "email": email,
                    "profile_picture_url": None,
                    "aes_key": aes_key
                }
            }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


@app.route('/refresh-token', methods=['POST'])
def refresh_token():
    """Refresh access token using a valid refresh token."""
    data = request.get_json()
    refresh_tok = data.get('refresh_token')
    
    if not refresh_tok:
        return jsonify({"error": "Refresh token is required"}), 400
    
    try:
        from jwt_config import verify_refresh_token
        from jwt_middleware import is_token_blacklisted
        
        # Verify without assuming 'verify_token' from import scope (handled by jwt_config? no, raw verify)
        # We need verify_token (generic) or specific logic. jwt_config has 'verify_token'.
        # But for refresh token we might want to check type.
        
        # Let's import inside function or use accessible one.
        # Actually jwt_config.verify_token decodes any token.
        # We need to check if it's blacklisted first.
        
        if is_token_blacklisted(refresh_tok):
            return jsonify({"error": "Refresh token has been revoked"}), 401
            
        # Check if session is active in DB (Single Session Enforcement)
        # If user logged in elsewhere, this record would be gone/replaced.
        if not session_manager.check_session_validity(refresh_tok):
             return jsonify({"error": "Session expired or logged in on another device"}), 401
            
        # Verify decode
        payload = pyjwt.decode(refresh_tok, options={"verify_signature": True}, key=os.getenv('JWT_SECRET_KEY'), algorithms=['HS256'])
        
        # Check type
        if payload.get('type') != 'refresh':
            return jsonify({"error": "Invalid token type"}), 401
            
        user_id = payload.get('user_id')
        session_id = payload.get('session_id')
        new_access_token = generate_access_token(user_id, session_id)
        # Optionally rotate refresh token? For now, keep it simple.
        
        return jsonify({
            "access_token": new_access_token
        }), 200
        
    except pyjwt.ExpiredSignatureError:
        return jsonify({"error": "Refresh token has expired. Please log in again."}), 401
    except Exception as e:
        return jsonify({"error": f"Invalid refresh token: {str(e)}"}), 401


@app.route('/logout', methods=['POST'])
@jwt_required
def logout():
    """Logout by blacklisting tokens."""
    try:
        auth_header = request.headers.get('Authorization')
        access_token = auth_header.split()[1] if auth_header else None
        
        data = request.get_json() or {}
        refresh_tok = data.get('refresh_token')
        
        # Decode exp for blacklist expiry
        # We already verified access_token in decorator, but need payload for exp.
        # Just allow pyjwt decode without verify to get exp quickly
        access_payload = pyjwt.decode(access_token, options={"verify_signature": False})
        access_exp = datetime.datetime.fromtimestamp(access_payload['exp'])
        
        blacklist_token(access_token, access_exp)
        
        if refresh_tok:
            try:
                refresh_payload = pyjwt.decode(refresh_tok, options={"verify_signature": False})
                refresh_exp = datetime.datetime.fromtimestamp(refresh_payload['exp'])
                blacklist_token(refresh_tok, refresh_exp)
            except:
                pass # Ignore invalid refresh token during logout
                
            # Remove from session DB to keep it clean
            session_manager.remove_session(refresh_tok)
        
        return jsonify({"message": "Logout successful"}), 200
    except Exception as e:
        return jsonify({"error": f"Logout failed: {str(e)}"}), 500


# Configure upload folder
basedir = os.path.abspath(os.path.dirname(__file__))
UPLOAD_FOLDER = os.path.join(basedir, 'static', 'profilePictures')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/profilePictures/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# @app.route('/encrypted-audio/<path:filepath>')
# @jwt_required
# def serve_encrypted_audio(filepath):
#     """Serve audio file encrypted with user's AES key.

#     The filepath should be like: AudioBooks/folder/file.wav
#     Server reads the file, encrypts with user's key, and returns encrypted data.
#     """
#     # Get user_id from JWT (set by jwt_required decorator)
#     user_id = getattr(request, 'user_id', None)
#     if not user_id:
#         return jsonify({"error": "Authentication required"}), 401

#     db = Database()
#     if not db.connect():
#         return jsonify({"error": "Database connection failed"}), 500

#     try:
#         # Get user's AES key
#         aes_key = get_or_create_user_aes_key(user_id, db)

#         # Build file path
#         base_dir = os.path.dirname(os.path.abspath(__file__))
#         file_path = os.path.join(base_dir, 'static', filepath)

#         # Security: ensure path is within static directory
#         real_path = os.path.realpath(file_path)
#         static_dir = os.path.realpath(os.path.join(base_dir, 'static'))
#         if not real_path.startswith(static_dir):
#             return jsonify({"error": "Invalid path"}), 403

#         if not os.path.exists(file_path):
#             return jsonify({"error": "File not found"}), 404

#         # Read and encrypt file
#         with open(file_path, 'rb') as f:
#             file_data = f.read()

#         encrypted_data = encrypt_file_data(file_data, aes_key)

#         # Return encrypted data
#         return Response(
#             encrypted_data,
#             mimetype='application/octet-stream',
#             headers={
#                 'Content-Disposition': f'attachment; filename=encrypted_audio.enc',
#                 'Content-Length': len(encrypted_data)
#             }
#         )

#     except Exception as e:
#         print(f"Encryption error: {e}")
#         return jsonify({"error": str(e)}), 500
#     finally:
#         db.disconnect()

@app.route('/upload-profile-picture', methods=['POST'])
@jwt_required
def upload_profile_picture():
    """Upload user profile picture with R2 fallback to local storage."""
    print(f"[PROFILE] Starting upload...")
    
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({"error": "User ID is required"}), 400

    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    
    # Check file type FIRST (don't seek yet)
    if not (file and allowed_file(file.filename)):
        return jsonify({"error": "File type not allowed (jpg, png, gif, webp)"}), 400
    
    print(f"[PROFILE] File type allowed: {file.filename}, user_id: {user_id}")
    
    # Now check file size (safe to seek after type check)
    file.seek(0, os.SEEK_END)
    file_size = file.tell()
    file.seek(0)
    print(f"[PROFILE] File size: {file_size} bytes")
    
    if file_size > 5 * 1024 * 1024:  # 5MB
        return jsonify({"error": "File too large (max 5MB)"}), 413

    db = Database()
    if not db.connect():
        print(f"[PROFILE] Database connection failed")
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # 1. Get user email to name the file
        print(f"[PROFILE] Querying user email...")
        email_query = "SELECT email FROM users WHERE id = %s"
        users = db.execute_query(email_query, (user_id,))
        if not users:
            return jsonify({"error": "User not found"}), 404
        
        user_email = users[0]['email']
        print(f"[PROFILE] User email: {user_email}")
        
        # 2. Create filename from email + TIMESTAMP to bust cache
        import time
        timestamp = int(time.time())
        file_ext = file.filename.rsplit('.', 1)[1].lower()
        safe_email_name = secure_filename(user_email)
        new_filename = f"{safe_email_name}_{timestamp}.{file_ext}"
        r2_key = f"profilePictures/{new_filename}"
        print(f"[PROFILE] New filename: {new_filename}")

        # 3. Try R2 upload first with timeout (max 20 seconds total)
        print(f"[PROFILE] Attempting R2 upload...")
        upload_start = time.time()
        r2_url = upload_fileobj_to_r2(file, r2_key)
        upload_elapsed = time.time() - upload_start

        if r2_url:
            # R2 upload succeeded
            print(f"[PROFILE] R2 succeeded in {upload_elapsed:.2f}s, updating DB...")
            update_query = "UPDATE users SET profile_picture_url = %s WHERE id = %s"
            db.execute_query(update_query, (r2_url, user_id))
            resolved_url = resolve_url(r2_url)
            print(f"[PROFILE] R2 upload succeeded for user {user_id} in {upload_elapsed:.2f}s")
            return jsonify({"message": "Profile picture updated via cloud", "url": resolved_url, "path": resolved_url}), 200
        else:
            # R2 failed or timed out - use local fallback
            print(f"[PROFILE] R2 failed after {upload_elapsed:.2f}s, using local fallback...")
            file.seek(0)
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], new_filename)
            file.save(file_path)
            relative_path = f"profilePictures/{new_filename}"
            full_url = f"{request.host_url}{relative_path}"
            update_query = "UPDATE users SET profile_picture_url = %s WHERE id = %s"
            db.execute_query(update_query, (relative_path, user_id))
            print(f"[PROFILE] Local fallback succeeded for user {user_id}")
            return jsonify({"message": "Profile picture updated locally", "url": full_url, "path": relative_path}), 200

    except Exception as e:
        print(f"[PROFILE] ERROR uploading for user {user_id}: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Upload failed: {str(e)}"}), 500
    finally:
        db.disconnect()

@app.route('/user/profile', methods=['GET'])
@jwt_required
def get_user_profile():
    """Get current user profile with fresh URLs."""
    try:
        auth_header = request.headers.get('Authorization')
        access_token = auth_header.split()[1]
        payload = pyjwt.decode(access_token, options={"verify_signature": False})
        user_id = payload.get('user_id')
        
        db = Database()
        if not db.connect():
            return jsonify({"error": "Database connection failed"}), 500
            
        try:
            query = "SELECT id, name, email, profile_picture_url, is_verified FROM users WHERE id = %s"
            users = db.execute_query(query, (user_id,))
            
            if not users:
                return jsonify({"error": "User not found"}), 404
                
            user = users[0]
            # Get AES key (though typically not needed for just profile view, but good for consistency)
            aes_key = get_or_create_user_aes_key(user['id'], db)
            
            return jsonify({
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": resolve_stored_url(user['profile_picture_url'], "profilePictures"),
                    "aes_key": aes_key
                }
            }), 200
        finally:
            db.disconnect()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def build_category_tree(categories, parent_id=None):
    """
    Recursively builds a tree of categories.
    categories is a list of dicts (rows) from the DB.
    """
    branch = []
    for cat in categories:
        # Check if this category is a child of the current parent_id
        # In the DB, parent_id might be None for root, or an int.
        # Python's None == None is True.
        
        # We need to handle the fact that execute_query returns dicts
        # assuming 'id', 'name', 'parent_id' are keys.
        
        row_parent_id = cat.get('parent_id')
        
        if row_parent_id == parent_id:
            children = build_category_tree(categories, cat['id'])
            
            # Construct dictionary matching the Flutter model expectations if possible
            # Flutter model uses 'id' (string) and 'title'. 
            # We use the 'slug' from DB as the 'id' for the app.
            
            node = {
                'id': cat['slug'], # Use slug (e.g. 'python') as ID
                'title': cat['name'],
                'children': children,
                # 'hasBooks': ... we could check this if we had books
            }
            branch.append(node)
            
    return branch

@app.route('/categories', methods=['GET'])
def get_categories():
    # Check cache
    cached_data = cache.get("categories")
    if cached_data:
        response = jsonify(cached_data)
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 min CDN cache
        return response

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # Fetch all categories
        result = db.execute_query("SELECT id, name, slug, parent_id FROM categories ORDER BY id ASC")
        
        if result is None:
             return jsonify({"error": "Failed to fetch categories"}), 500

        # Build tree
        tree = build_category_tree(result)
        
        cache.set("categories", tree, 300)
        response = jsonify(tree)
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 min CDN cache
        return response
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/playlist/<int:book_id>', methods=['GET'])
@jwt_required
def get_playlist(book_id):
    user_id = request.args.get('user_id')
    
    # Check cache (30s)
    cache_key = f"playlist:{user_id}:{book_id}" if user_id else f"playlist:anon:{book_id}"
    cached_pl = cache.get(cache_key)
    if cached_pl:
        return jsonify(cached_pl)
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    try:
        if user_id:
             query = """
                SELECT p.*, 
                       CASE WHEN uct.id IS NOT NULL THEN TRUE ELSE FALSE END as is_completed,
                       COALESCE(utp.position_seconds, 0) as last_position
                FROM playlist_items p
                LEFT JOIN user_completed_tracks uct ON p.id = uct.track_id AND uct.user_id = %s
                LEFT JOIN user_track_progress utp ON p.id = utp.playlist_item_id AND utp.user_id = %s
                WHERE p.book_id = %s 
                ORDER BY p.track_order ASC
             """
             result = db.execute_query(query, (user_id, user_id, book_id))

        else:
             query = "SELECT *, FALSE as is_completed FROM playlist_items WHERE book_id = %s ORDER BY track_order ASC"
             result = db.execute_query(query, (book_id,))
             
        if result:
            # Normalize boolean (MySQL returns 1/0) and resolve file URLs
            for item in result:
                item['is_completed'] = bool(item.get('is_completed', 0))
                if item.get('file_path'):
                    item['file_path'] = resolve_stored_url(item['file_path'], "AudioBooks")

            # Check for quiz containing questions
            quiz_exists = False
            q_query = """
                SELECT q.id 
                FROM quizzes q
                INNER JOIN quiz_questions qq ON q.id = qq.quiz_id
                WHERE q.book_id = %s AND q.playlist_item_id IS NULL
                LIMIT 1
            """
            # Reuse DB connection? Yes.
            q_res = db.execute_query(q_query, (book_id,))
            if q_res:
                quiz_exists = True
                
            # Check if quiz is passed by THIS user
            quiz_passed = False
            if quiz_exists and user_id:
               # We need quiz_id. The previous query just checked existence.
               # Let's get quiz_id
               qid_query = "SELECT id FROM quizzes WHERE book_id = %s AND playlist_item_id IS NULL"
               qid_res = db.execute_query(qid_query, (book_id,))
               if qid_res:
                   quiz_id = qid_res[0]['id']
                   pass_query = "SELECT is_passed FROM user_quiz_results WHERE user_id = %s AND quiz_id = %s ORDER BY completed_at DESC LIMIT 1"
                   pass_res = db.execute_query(pass_query, (user_id, quiz_id))
                   if pass_res and pass_res[0]['is_passed']:
                       quiz_passed = True

            # Check for Track Quizzes
            track_quizzes = {}
            if user_id:
                # Get all quizzes for this book's tracks
                # Map playlist_item_id -> {has_quiz, passed}
                tq_query = """
                    SELECT q.playlist_item_id, q.id as quiz_id,
                           (SELECT is_passed FROM user_quiz_results uqr WHERE uqr.quiz_id = q.id AND uqr.user_id = %s ORDER BY completed_at DESC LIMIT 1) as is_passed
                    FROM quizzes q
                    WHERE q.book_id = %s AND q.playlist_item_id IS NOT NULL
                """
                tq_res = db.execute_query(tq_query, (user_id, book_id))
                if tq_res:
                    for row in tq_res:
                        track_quizzes[str(row['playlist_item_id'])] = {
                            "has_quiz": True,
                            "is_passed": bool(row['is_passed'])
                        }
            else:
                # Just check existence
                tq_query = "SELECT playlist_item_id FROM quizzes WHERE book_id = %s AND playlist_item_id IS NOT NULL"
                tq_res = db.execute_query(tq_query, (book_id,))
                if tq_res:
                    for row in tq_res:
                        track_quizzes[str(row['playlist_item_id'])] = {
                           "has_quiz": True,
                           "is_passed": False
                        }
                
            # Fetch pdf_path for the book
            pdf_query = "SELECT pdf_path FROM books WHERE id = %s"
            pdf_res = db.execute_query(pdf_query, (book_id,))
            pdf_path = resolve_stored_url(pdf_res[0]['pdf_path'], "AudioBooks") if pdf_res and pdf_res[0]['pdf_path'] else None

            resp = {
                "tracks": result,
                "has_quiz": quiz_exists,
                "quiz_passed": quiz_passed,
                "track_quizzes": track_quizzes,
                "pdf_path": pdf_path
            }
            if cache_key:
                cache.set(cache_key, resp, 30)
            return jsonify(resp)
        
        # Fallback for "Single Book" treated as Playlist
        book_query = "SELECT title, audio_path, duration_seconds, pdf_path FROM books WHERE id = %s"
        book_res = db.execute_query(book_query, (book_id,))
        if book_res:
            book = book_res[0]
            audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")

            # Check if book is "read" if it's a single file?
            # We can check user_books.is_read
            is_completed = False
            if user_id:
                ub_query = "SELECT is_read FROM user_books WHERE user_id = %s AND book_id = %s"
                ub_res = db.execute_query(ub_query, (user_id, book_id))
                if ub_res:
                    is_completed = bool(ub_res[0]['is_read'])

            synthetic_item = {
                "id": -1, # Virtual ID
                "book_id": book_id,
                "file_path": audio_path,
                "title": book['title'],
                "duration_seconds": book['duration_seconds'],
                "track_order": 0,
                "is_completed": is_completed
            }
            
            # Check if quiz exists
            quiz_exists = False
            q_query = "SELECT id FROM quizzes WHERE book_id = %s"
            q_res = db.execute_query(q_query, (book_id,))
            if q_res:
                quiz_exists = True

            pdf_path = resolve_stored_url(book['pdf_path'], "AudioBooks") if book.get('pdf_path') else None
            resp = {"tracks": [synthetic_item], "has_quiz": quiz_exists, "pdf_path": pdf_path}
            if cache_key:
                cache.set(cache_key, resp, 30)
            return jsonify(resp)
            
        resp = {"tracks": [], "has_quiz": False, "pdf_path": None}
        if cache_key:
            cache.set(cache_key, resp, 30)
        return jsonify(resp)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/quiz', methods=['POST'])
@jwt_required
def save_quiz():
    user_id = getattr(request, 'user_id', None)
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    # Admin check
    if not is_admin_user(user_id, db):
        db.disconnect()
        return jsonify({"error": "Admin access required"}), 403

    data = request.get_json()
    book_id = data.get('book_id')
    playlist_item_id = data.get('playlist_item_id') # Optional
    questions = data.get('questions') # List of dicts
    
    if not all([book_id, questions]):
        db.disconnect()
        return jsonify({"error": "Missing book_id or questions"}), 400
        
    try:
        # Check if quiz exists, if so, we can replace it or append.
        # Simplest: Delete old, create new.
        # But we need to handle the quiz_id.
        
        # 1. Get or Create Quiz ID
        cursor = db.connection.cursor()
        
        check_query = "SELECT id FROM quizzes WHERE book_id = %s"
        params = [book_id]
        
        if playlist_item_id:
            check_query += " AND playlist_item_id = %s"
            params.append(playlist_item_id)
        else:
             check_query += " AND playlist_item_id IS NULL"
             
        cursor.execute(check_query, tuple(params))
        res = cursor.fetchone()
        
        if res:
            quiz_id = res[0]
            # Clear old questions
            cursor.execute("DELETE FROM quiz_questions WHERE quiz_id = %s", (quiz_id,))
        else:
            if playlist_item_id:
                ins_q = "INSERT INTO quizzes (book_id, playlist_item_id) VALUES (%s, %s) RETURNING id"
                cursor.execute(ins_q, (book_id, playlist_item_id))
            else:
                ins_q = "INSERT INTO quizzes (book_id) VALUES (%s) RETURNING id"
                cursor.execute(ins_q, (book_id,))
                
            quiz_id = cursor.fetchone()[0]
            
        # 2. Insert Questions
        q_insert = """
            INSERT INTO quiz_questions 
            (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, order_index)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        for idx, q in enumerate(questions):
            cursor.execute(q_insert, (
                quiz_id,
                q['question'],
                q['options'][0],
                q['options'][1],
                q['options'][2],
                q['options'][3],
                q['correctAnswer'], # Expecting 'A', 'B', 'C', 'D'
                idx
            ))
            
        db.connection.commit()
        cursor.close()
        
        return jsonify({"message": "Quiz saved successfully"}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()
        
@app.route('/quiz/<int:book_id>', methods=['GET'])
def get_quiz(book_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Get Quiz ID
        playlist_item_id = request.args.get('playlist_item_id')
        
        q_query = "SELECT id FROM quizzes WHERE book_id = %s"
        params = [book_id]
        
        if playlist_item_id:
            q_query += " AND playlist_item_id = %s"
            params.append(playlist_item_id)
        else:
            q_query += " AND playlist_item_id IS NULL"
            
        q_res = db.execute_query(q_query, tuple(params))
        
        if not q_res:
            return jsonify([]) # No quiz
            
        quiz_id = q_res[0]['id']
        
        # Get Questions
        ques_query = """
            SELECT question_text, option_a, option_b, option_c, option_d, correct_answer
            FROM quiz_questions 
            WHERE quiz_id = %s 
            ORDER BY order_index ASC
        """
        questions = db.execute_query(ques_query, (quiz_id,))
        
        # Format for frontend
        formatted = []
        for q in questions:
            formatted.append({
                "question": q['question_text'],
                "options": [q['option_a'], q['option_b'], q['option_c'], q['option_d']],
                "correctAnswer": q['correct_answer']
            })
            
        return jsonify(formatted)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


def calculate_listen_percentage(db, user_id, book_id, is_playlist, total_duration):
    """
    Calculate the listen percentage for a book.
    For completed tracks, uses full duration. For in-progress tracks, uses last position.
    """
    # Check if marked as read (completed) - Force 100%
    read_query = "SELECT is_read FROM user_books WHERE user_id = %s AND book_id = %s"
    read_res = db.execute_query(read_query, (user_id, book_id))
    if read_res and read_res[0].get('is_read') == 1:
        return 100.0

    if total_duration <= 0:
        return 0.0
    
    total_listened_seconds = 0
    
    if is_playlist:
        # For playlists: sum up progress across all tracks
        playlist_progress_query = """
            SELECT 
                pi.id as playlist_item_id,
                pi.duration_seconds,
                COALESCE(MAX(ph.played_seconds), 0) as last_position,
                (SELECT COUNT(*) FROM user_completed_tracks WHERE user_id = %s AND track_id = pi.id) as is_completed
            FROM playlist_items pi
            LEFT JOIN playback_history ph ON ph.playlist_item_id = pi.id AND ph.user_id = %s
            WHERE pi.book_id = %s
            GROUP BY pi.id, pi.duration_seconds
        """
        tracks_result = db.execute_query(playlist_progress_query, (user_id, user_id, book_id))
        
        if tracks_result:
            for track in tracks_result:
                track_duration = track['duration_seconds'] or 0
                is_completed = track['is_completed'] > 0
                
                if is_completed and track_duration > 0:
                    # Track is completed - use full duration
                    listened = track_duration
                else:
                    # Track not completed - use last recorded position
                    last_pos = track['last_position'] or 0
                    listened = min(last_pos, track_duration) if track_duration > 0 else last_pos
                
                total_listened_seconds += listened
    else:
        # For single files: get the MAX position from playback_history
        single_progress_query = """
            SELECT COALESCE(MAX(played_seconds), 0) as last_position
            FROM playback_history
            WHERE user_id = %s AND book_id = %s
        """
        single_result = db.execute_query(single_progress_query, (user_id, book_id))
        if single_result:
            total_listened_seconds = single_result[0]['last_position'] or 0
    
    # Calculate percentage
    percentage = (total_listened_seconds / total_duration * 100) if total_duration > 0 else 0
    return round(percentage, 2)

@app.route('/books', methods=['GET'])
def get_books():
    import time
    timings = {}
    start_total = time.time()
    
    start = time.time()
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    timings['db_connect'] = round((time.time() - start) * 1000)
    
    try:
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 5, type=int)
        search_query = request.args.get('q', '', type=str)
        user_id = request.args.get('user_id', None, type=int)  # Optional user_id for progress
        
        offset = (page - 1) * limit

        params = []

        is_fav_join = ""
        is_fav_col = "0 as is_favorite"
        if user_id:
             is_fav_join = "LEFT JOIN favorites fav ON fav.book_id = b.id AND fav.user_id = %s"
             is_fav_col = "CASE WHEN fav.book_id IS NOT NULL THEN 1 ELSE 0 END as is_favorite"
             params.append(user_id)

        base_select = f"""
            SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, c.slug as category_slug,
                   u.name as posted_by_name, b.description, b.price, b.posted_by_user_id, b.duration_seconds, b.pdf_path,
                   b.premium, b.background_music_id,
                   {is_fav_col},
                   COALESCE(pi_count.cnt, 0) as playlist_count,
                   br_stats.avg_rating as average_rating,
                   COALESCE(br_stats.rating_cnt, 0) as rating_count
            FROM books b
            LEFT JOIN categories c ON b.primary_category_id = c.id
            LEFT JOIN users u ON b.posted_by_user_id = u.id
            LEFT JOIN (
                SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id
            ) pi_count ON pi_count.book_id = b.id
            LEFT JOIN (
                SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id
            ) br_stats ON br_stats.book_id = b.id
            {is_fav_join}
        """

        sort_by = request.args.get('sort', 'newest', type=str)

        if search_query:
             query = base_select + " WHERE b.title ILIKE %s"
             params.append(f"%{search_query}%")
        else:
            query = base_select

        if sort_by == 'popular':
            query += """ ORDER BY (
                COALESCE(br_stats.avg_rating, 0) * COALESCE(br_stats.rating_cnt, 0)
            ) DESC NULLS LAST, b.id DESC"""
        else:
            query += " ORDER BY b.id DESC" 
        
        query += " LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        start = time.time()
        books_result = db.execute_query(query, tuple(params))
        timings['main_query'] = round((time.time() - start) * 1000)
        
        if not books_result:
            timings['total'] = round((time.time() - start_total) * 1000)
            print(f"[TIMING] get_books (empty): {timings}")
            return jsonify([])
        
        # Collect all book IDs for batch queries
        book_ids = [row['id'] for row in books_result]
        
        # ============ BATCH QUERY 1: Subcategories for all books ============
        subcats_by_book = {}
        if book_ids:
            placeholders = ','.join(['%s'] * len(book_ids))
            subcats_query = f"""
                SELECT bc.book_id, c.slug 
                FROM book_categories bc
                JOIN categories c ON bc.category_id = c.id
                WHERE bc.book_id IN ({placeholders})
            """
            subcats_result = db.execute_query(subcats_query, tuple(book_ids))
            if subcats_result:
                for row in subcats_result:
                    bid = row['book_id']
                    if bid not in subcats_by_book:
                        subcats_by_book[bid] = []
                    subcats_by_book[bid].append(row['slug'])
                # ============ BATCH QUERY 2: User progress data (if user_id provided) ============
        progress_by_book = {}
        read_status_by_book = {}
        user_bg_prefs = {}
        
        if user_id and book_ids:
            placeholders = ','.join(['%s'] * len(book_ids))
            
            # 2a: Batch query for read status AND background music preference
            read_query = f"""
                SELECT book_id, is_read, background_music_id
                FROM user_books 
                WHERE user_id = %s AND book_id IN ({placeholders})
            """
            read_result = db.execute_query(read_query, (user_id, *book_ids))
            if read_result:
                for row in read_result:
                    read_status_by_book[row['book_id']] = row.get('is_read', False)
                    if row.get('background_music_id'):
                        user_bg_prefs[row['book_id']] = row['background_music_id']
            
            # 2b: Batch query for single-book progress (non-playlist books)
            single_progress_query = f"""
                SELECT book_id, COALESCE(MAX(played_seconds), 0) as last_position
                FROM playback_history
                WHERE user_id = %s AND book_id IN ({placeholders})
                GROUP BY book_id
            """
            single_result = db.execute_query(single_progress_query, (user_id, *book_ids))
            if single_result:
                for row in single_result:
                    progress_by_book[row['book_id']] = {'single_progress': row['last_position']}
            
            # 2c: Batch query for playlist progress (all tracks for all books)
            playlist_progress_query = f"""
                SELECT 
                    pi.book_id,
                    pi.id as playlist_item_id,
                    pi.duration_seconds,
                    COALESCE(MAX(ph.played_seconds), 0) as last_position,
                    (SELECT COUNT(*) FROM user_completed_tracks WHERE user_id = %s AND track_id = pi.id) as is_completed
                FROM playlist_items pi
                LEFT JOIN playback_history ph ON ph.playlist_item_id = pi.id AND ph.user_id = %s
                WHERE pi.book_id IN ({placeholders})
                GROUP BY pi.book_id, pi.id, pi.duration_seconds
            """
            playlist_result = db.execute_query(playlist_progress_query, (user_id, user_id, *book_ids))
            if playlist_result:
                for row in playlist_result:
                    bid = row['book_id']
                    if bid not in progress_by_book:
                        progress_by_book[bid] = {'tracks': []}
                    if 'tracks' not in progress_by_book[bid]:
                        progress_by_book[bid]['tracks'] = []
                    progress_by_book[bid]['tracks'].append({
                        'duration': row['duration_seconds'] or 0,
                        'last_position': row['last_position'] or 0,
                        'is_completed': row['is_completed'] > 0
                    })
        
        # ============ Build response ============
        start = time.time()
        books = []
        for row in books_result:
            book_id = row['id']
            
            # Get subcategories from batch result
            subcategory_ids = subcats_by_book.get(book_id, [])
            
            # Resolve URLs
            audio_path = resolve_stored_url(row['audio_path'], "AudioBooks")
            cover_path, cover_thumbnail_path = resolve_cover_urls(row['cover_image_path'])

            # Calculate listen percentage from batch data
            percentage = None
            if user_id:
                # Check if book is marked as read
                if read_status_by_book.get(book_id):
                    percentage = 100.0
                else:
                    total_duration = row['duration_seconds'] or 0
                    is_playlist = row['playlist_count'] > 0
                    
                    if total_duration > 0:
                        if is_playlist:
                            # Calculate from track data
                            tracks = progress_by_book.get(book_id, {}).get('tracks', [])
                            total_listened = 0
                            for track in tracks:
                                if track['is_completed'] and track['duration'] > 0:
                                    total_listened += track['duration']
                                else:
                                    total_listened += min(track['last_position'], track['duration']) if track['duration'] > 0 else track['last_position']
                            percentage = round((total_listened / total_duration * 100), 2) if total_duration > 0 else 0
                        else:
                            # Single book progress
                            single_progress = progress_by_book.get(book_id, {}).get('single_progress', 0)
                            percentage = round((single_progress / total_duration * 100), 2) if total_duration > 0 else 0
                    else:
                        percentage = 0
            
            # Determine Background Music
            # Prioritize User Preference -> then Book Default
            bg_music_id = user_bg_prefs.get(book_id)
            if bg_music_id is None:
                bg_music_id = row.get('background_music_id')

            book_data = {
                "id": str(book_id),
                "title": row['title'],
                "author": row['author'],
                "audioUrl": audio_path,
                "coverUrl": cover_path,
                "coverUrlThumbnail": cover_thumbnail_path,
                "categoryId": row['category_slug'] or "",
                "subcategoryIds": subcategory_ids,
                "postedBy": row['posted_by_name'] or "Unknown",
                "description": row['description'],
                "price": float(row['price']) if row['price'] else 0.0,
                "postedByUserId": str(row['posted_by_user_id']),
                "isPlaylist": row['playlist_count'] > 0,
                "duration": row['duration_seconds'] or 0,
                "averageRating": round(float(row['average_rating']), 1) if row['average_rating'] else 0.0,
                "ratingCount": row['rating_count'] or 0,
                "pdfUrl": resolve_stored_url(row['pdf_path'], "AudioBooks"),
                "premium": bool(row['premium']),
                "isFavorite": bool(row.get('is_favorite', 0)),
                "backgroundMusicId": bg_music_id
            }
            
            if percentage is not None:
                book_data["percentage"] = percentage
            
            books.append(book_data)
        
        timings['build_response'] = round((time.time() - start) * 1000)
        timings['total'] = round((time.time() - start_total) * 1000)
        print(f"[TIMING] get_books: {timings}")
        
        return jsonify(books)
        
    except Exception as e:
        print(f"Error in get_books: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# ===================== COMBINED DISCOVER ENDPOINT =====================
@app.route('/discover', methods=['GET'])
def get_discover():
    """
    Combined endpoint that returns all data needed for the discover screen in one call:
    - newReleases: 5 newest books
    - topPicks: 5 most popular books
    - allBooks: paginated list of all books
    - favorites: list of favorite book IDs for the user
    - isSubscribed: subscription status
    - listenHistory: books the user has started listening to
    """
    import time
    start_total = time.time()
    
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        user_id = request.args.get('user_id', None, type=int)
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 10, type=int)
        
        # Check cache (both anonymous and authenticated requests)
        cache_key = f"discover:{user_id or 'anon'}:{page}:{limit}"
        cached_data = cache.get(cache_key)
        if cached_data:
            return jsonify(cached_data)

        offset = (page - 1) * limit
        
        # Helper function to build book list from query results
        def build_books(books_result, subcats_by_book, progress_by_book, read_status_by_book, favIds, user_bg_prefs):
            books = []
            for row in books_result:
                book_id = row['id']
                subcategory_ids = subcats_by_book.get(book_id, [])
                audio_path = resolve_stored_url(row['audio_path'], "AudioBooks")
                cover_path, cover_thumbnail_path = resolve_cover_urls(row['cover_image_path'])
                
                percentage = None
                if user_id:
                    if read_status_by_book.get(book_id):
                        percentage = 100.0
                    else:
                        total_duration = row['duration_seconds'] or 0
                        is_playlist = row.get('playlist_count', 0) > 0
                        if total_duration > 0:
                            if is_playlist:
                                tracks = progress_by_book.get(book_id, {}).get('tracks', [])
                                total_listened = 0
                                for track in tracks:
                                    if track['is_completed'] and track['duration'] > 0:
                                        total_listened += track['duration']
                                    else:
                                        total_listened += min(track['last_position'], track['duration']) if track['duration'] > 0 else track['last_position']
                                percentage = round((total_listened / total_duration * 100), 2)
                            else:
                                single_progress = progress_by_book.get(book_id, {}).get('single_progress', 0)
                                percentage = round((single_progress / total_duration * 100), 2)
                        else:
                            percentage = 0
                
                # Determine Background Music
                # Prioritize User Preference -> then Book Default
                bg_music_id = user_bg_prefs.get(book_id)
                if bg_music_id is None:
                    bg_music_id = row.get('background_music_id')

                books.append({
                    "id": str(book_id),
                    "title": row['title'],
                    "author": row['author'],
                    "audioUrl": audio_path,
                    "coverUrl": cover_path,
                    "coverUrlThumbnail": cover_thumbnail_path,
                    "categoryId": row.get('category_slug') or "",
                    "subcategoryIds": subcategory_ids,
                    "postedBy": row.get('posted_by_name') or "Unknown",
                    "description": row.get('description'),
                    "price": float(row['price']) if row.get('price') else 0.0,
                    "postedByUserId": str(row.get('posted_by_user_id', 0)),
                    "isPlaylist": row.get('playlist_count', 0) > 0,
                    "duration": row['duration_seconds'] or 0,
                    "averageRating": round(float(row['average_rating']), 1) if row.get('average_rating') else 0.0,
                    "ratingCount": row.get('rating_count') or 0,
                    "pdfUrl": resolve_stored_url(row.get('pdf_path'), "AudioBooks"),
                    "premium": row.get('premium') or 0,
                    "isFavorite": int(book_id) in favIds,
                    "percentage": percentage,
                    "lastPosition": row.get('last_position'),
                    "backgroundMusicId": bg_music_id,
                    "currentPlaylistItemId": row.get('current_playlist_item_id')
                })
            return books
        
        # Get favorites for user
        favIds = []
        if user_id:
            fav_result = db.execute_query("SELECT book_id FROM favorites WHERE user_id = %s", (user_id,))
            if fav_result:
                favIds = [row['book_id'] for row in fav_result]
        
        # Get subscription status
        is_subscribed = False
        if user_id:
            is_subscribed = is_subscriber(user_id, db)
        
        # Base query for books - uses JOINs instead of correlated subqueries
        base_select = """
            SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, c.slug as category_slug,
                   u.name as posted_by_name, b.description, b.price, b.posted_by_user_id, b.duration_seconds, b.pdf_path,
                   b.premium, b.background_music_id,
                   COALESCE(pi_count.cnt, 0) as playlist_count,
                   br_stats.avg_rating as average_rating,
                   COALESCE(br_stats.rating_cnt, 0) as rating_count
            FROM books b
            LEFT JOIN categories c ON b.primary_category_id = c.id
            LEFT JOIN users u ON b.posted_by_user_id = u.id
            LEFT JOIN (
                SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id
            ) pi_count ON pi_count.book_id = b.id
            LEFT JOIN (
                SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id
            ) br_stats ON br_stats.book_id = b.id
        """

        # Fetch all three book lists in one go (newest, popular, paginated)
        newest_result = db.execute_query(base_select + " ORDER BY b.id DESC LIMIT 5")
        popular_result = db.execute_query(base_select + """ ORDER BY (
            COALESCE(br_stats.avg_rating, 0) * COALESCE(br_stats.rating_cnt, 0)
        ) DESC NULLS LAST, b.id DESC LIMIT 5""")
        all_result = db.execute_query(base_select + " ORDER BY b.id DESC LIMIT %s OFFSET %s", (limit, offset))
        
        # Collect all book IDs for batch subcategory/progress queries
        all_book_ids = set()
        for result in [newest_result, popular_result, all_result]:
            if result:
                for row in result:
                    all_book_ids.add(row['id'])
        all_book_ids = list(all_book_ids)
        
        # Batch fetch subcategories
        subcats_by_book = {}
        if all_book_ids:
            placeholders = ','.join(['%s'] * len(all_book_ids))
            subcats_result = db.execute_query(f"""
                SELECT bc.book_id, c.slug 
                FROM book_categories bc
                JOIN categories c ON bc.category_id = c.id
                WHERE bc.book_id IN ({placeholders})
            """, tuple(all_book_ids))
            if subcats_result:
                for row in subcats_result:
                    bid = row['book_id']
                    if bid not in subcats_by_book:
                        subcats_by_book[bid] = []
                    subcats_by_book[bid].append(row['slug'])
        
        # Batch fetch progress data (if user logged in)
        progress_by_book = {}
        read_status_by_book = {}
        user_bg_prefs = {}
        
        if user_id and all_book_ids:
            placeholders = ','.join(['%s'] * len(all_book_ids))
            
            read_result = db.execute_query(f"""
                SELECT book_id, is_read, background_music_id FROM user_books 
                WHERE user_id = %s AND book_id IN ({placeholders})
            """, (user_id, *all_book_ids))
            if read_result:
                for row in read_result:
                    read_status_by_book[row['book_id']] = row.get('is_read', False)
                    if row.get('background_music_id'):
                        user_bg_prefs[row['book_id']] = row['background_music_id']
            
            single_result = db.execute_query(f"""
                SELECT book_id, COALESCE(MAX(played_seconds), 0) as last_position
                FROM playback_history WHERE user_id = %s AND book_id IN ({placeholders})
                GROUP BY book_id
            """, (user_id, *all_book_ids))
            if single_result:
                for row in single_result:
                    progress_by_book[row['book_id']] = {'single_progress': row['last_position']}
        
        # Get listen history (using user_books table like /listen-history endpoint)
        listen_history = []
        if user_id:
            history_query = """
                SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, b.duration_seconds,
                       b.premium, b.pdf_path, c.slug as category_slug,
                       ub.last_played_position_seconds as last_position,
                       ub.current_playlist_item_id,
                       COALESCE(pi_count.cnt, 0) as playlist_count,
                       br_stats.avg_rating as average_rating,
                       COALESCE(br_stats.rating_cnt, 0) as rating_count
                FROM user_books ub
                JOIN books b ON ub.book_id = b.id
                LEFT JOIN categories c ON b.primary_category_id = c.id
                LEFT JOIN (
                    SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id
                ) pi_count ON pi_count.book_id = b.id
                LEFT JOIN (
                    SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id
                ) br_stats ON br_stats.book_id = b.id
                WHERE ub.user_id = %s AND ub.last_played_position_seconds > 0 AND (ub.is_read = 0 OR ub.is_read IS NULL)
                ORDER BY ub.last_accessed_at DESC
            """
            history_result = db.execute_query(history_query, (user_id,))
            if history_result:
                listen_history = build_books(history_result, subcats_by_book, progress_by_book, read_status_by_book, favIds, user_bg_prefs)
        
        # Build response
        # Fetch categories (reuse the same logic as /categories endpoint)
        categories_result = db.execute_query("SELECT id, name, slug, parent_id FROM categories ORDER BY id ASC")
        categories_tree = build_category_tree(categories_result) if categories_result else []
        
        # Build response
        response = {
            "newReleases": build_books(newest_result or [], subcats_by_book, progress_by_book, read_status_by_book, favIds, user_bg_prefs),
            "topPicks": build_books(popular_result or [], subcats_by_book, progress_by_book, read_status_by_book, favIds, user_bg_prefs),
            "allBooks": build_books(all_result or [], subcats_by_book, progress_by_book, read_status_by_book, favIds, user_bg_prefs),
            "favorites": favIds,
            "isSubscribed": is_subscribed,
            "listenHistory": listen_history,
            "categories": categories_tree,
        }
        
        print(f"[TIMING] get_discover: total={round((time.time() - start_total) * 1000)}ms")
        
        cache.set(cache_key, response, 30)
        return jsonify(response)
        
    except Exception as e:
        print(f"Error in get_discover: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()



# ===================== REELS ENDPOINT =====================
@app.route('/reels', methods=['GET'])
@jwt_required
def get_reels():
    """
    Returns all books with their playlist items for the Reels feature.
    Restricted to subscribers.
    Also returns the user's saved offset so client doesn't need separate call.
    """
    user_id = request.args.get('user_id')
    
    if not user_id:
        return jsonify({"error": "User ID required"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    # STATEFUL REELS: Server manages the offset.
    # Client asks for "more", we give next batch and update offset.
    # STATEFUL REELS: Hybrid approach.
    # Client CAN send offset. If valid, we use it. If not, we use DB.
    # This allows client to retry specific pages or sync state.
    limit = int(request.args.get('limit', 5))
    client_offset = request.args.get('offset') # string or None

    try:
        # 1. Determine start offset
        offset = 0
        saved_offset = 0
        
        # Get DB offset (always needed for fallback or "Resume")
        try:
            offset_result = db.execute_query("SELECT reels_offset FROM users WHERE id = %s", (user_id,))
            if offset_result and offset_result[0].get('reels_offset') is not None:
                saved_offset = offset_result[0]['reels_offset']
        except Exception as e:
            print(f"Could not fetch reels_offset: {e}")
        
        # Decide which offset to use
        if client_offset is not None:
            try:
                offset = int(client_offset)
                # If client says 0, but we have saved progress, should we override?
                # User said: "if current offset is 0, offset should be 5... on server... update offset"
                # If client sends 0, they might mean "Restart" or "Fresh".
                # But usually we want Resume.
                # If client sends explicit 0, we treat it as 0 unless smart resume is active?
                # Let's trust client if they send explicit value, BUT if value is 0 and we have >0, maybe resume?
                # User complained "returns to beginning always".
                if offset == 0:
                     offset = saved_offset
            except ValueError:
                offset = saved_offset
        else:
            offset = saved_offset
        
        # Check subscription
        user_id_int = int(user_id)
        subscribed = is_subscriber(user_id_int, db)
        
        if not subscribed:
             return jsonify({
                 "isSubscribed": False,
                 "books": [],
                 "hasMore": False,
                 "savedOffset": offset
             }), 200

        # 2. Get total book count
        count_result = db.execute_query("SELECT COUNT(*) as count FROM books")
        if not count_result:
             print("[REELS] Error: Could not fetch book count.")
             return jsonify({"isSubscribed": True, "books": [], "hasMore": False, "savedOffset": offset}), 200
             
        total_books = count_result[0]['count']
        
        if total_books == 0:
            return jsonify({"isSubscribed": True, "books": [], "hasMore": False, "savedOffset": 0}), 200
        
        # 3. Calculate effective offset (circular)
        effective_offset = offset % total_books
        print(f"[REELS] Stateful Fetch: User {user_id} at offset {offset} (effective {effective_offset}). Fetching {limit} items.")

        # 4. Fetch books (Joined with user_books for background music preference)
        books_query = """
            SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, b.duration_seconds,
                   b.description, b.posted_by_user_id, b.background_music_id as default_bg_id,
                   ub.background_music_id as user_bg_id
            FROM books b
            LEFT JOIN user_books ub ON b.id = ub.book_id AND ub.user_id = %s
            ORDER BY b.id DESC
            LIMIT %s OFFSET %s
        """
        books_result = db.execute_query(books_query, (user_id, limit + 5, effective_offset))
        
        # Wrap around logic
        if books_result and len(books_result) < limit:
            remaining = limit - len(books_result)
            wrap_query = """
                SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, b.duration_seconds,
                       b.description, b.posted_by_user_id, b.background_music_id as default_bg_id,
                       ub.background_music_id as user_bg_id
                FROM books b
                LEFT JOIN user_books ub ON b.id = ub.book_id AND ub.user_id = %s
                ORDER BY b.id DESC
                LIMIT %s OFFSET 0
            """
            wrap_result = db.execute_query(wrap_query, (user_id, remaining + 5,))
            if wrap_result:
                existing_ids = {b['id'] for b in books_result}
                for book in wrap_result:
                    if book['id'] not in existing_ids:
                        books_result.append(book)
        
        # 5. IMMEDIATE UPDATE: Advance offset for next time
        # We increment by 'limit' to advance by page size, regardless of actual returned (due to wrap).
        # Ensures smooth pagination.
        new_offset = (offset + limit) % total_books
        try:
            db.execute_query("UPDATE users SET reels_offset = %s WHERE id = %s", (new_offset, user_id))
            print(f"[REELS] Updated offset to {new_offset} for user {user_id}")
        except Exception as e:
            print(f"Failed to update reels_offset: {e}")

        if not books_result:
             return jsonify({"isSubscribed": True, "books": [], "hasMore": True, "savedOffset": offset}), 200

        # Collect IDs and fetch playlist items (same as before)
        book_ids = list(set([b['id'] for b in books_result]))
        
        playlist_result = []
        if book_ids:
            placeholders = ','.join(['%s'] * len(book_ids))
            playlist_query = f"""
                SELECT id, book_id, file_path, title, duration_seconds, track_order
                FROM playlist_items
                WHERE book_id IN ({placeholders})
                ORDER BY book_id, track_order
            """
            playlist_result = db.execute_query(playlist_query, tuple(book_ids))
        
        tracks_by_book = {}
        if playlist_result:
            for row in playlist_result:
                bid = row['book_id']
                if bid not in tracks_by_book:
                    tracks_by_book[bid] = []
                audio_path = resolve_stored_url(row['file_path'], "AudioBooks")
                tracks_by_book[bid].append({
                    "id": str(row['id']),
                    "title": row['title'] or "Unknown Track",
                    "audioUrl": audio_path or "",
                    "duration": row['duration_seconds'] or 0,
                    "order": row['track_order'] or 0
                })
        
        books_data = []
        for book in books_result:
            try:
                book_id = book['id']
                cover_path, cover_thumb = resolve_cover_urls(book['cover_image_path'])
                audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")
                tracks = tracks_by_book.get(book_id, [])
                
                if not tracks and book['audio_path']:
                    tracks = [{
                        "id": f"book_{book_id}",
                        "title": book['title'] or "Untitled",
                        "audioUrl": audio_path or "",
                        "duration": book['duration_seconds'] or 0,
                        "order": 0
                    }]
                
                if not tracks:
                    continue
                
                active_bg_id = book.get('user_bg_id')
                if active_bg_id is None:
                    active_bg_id = book.get('default_bg_id')

                books_data.append({
                    "id": str(book_id),
                    "title": book['title'] or "Untitled",
                    "author": book['author'] or "Unknown",
                    "coverUrl": cover_path,
                    "coverUrlThumbnail": cover_thumb,
                    "description": book['description'] or "",
                    "postedByUserId": str(book['posted_by_user_id'] or ""),
                    "categoryId": "",
                    "subcategoryIds": [],
                    "audioUrl": audio_path if book['audio_path'] else "",
                    "isPlaylist": len(tracks) > 0,
                    "isPremium": True,
                    "price": 0.0,
                    "averageRating": 0.0,
                    "ratingCount": 0,
                    "tracks": tracks,
                    "backgroundMusicId": active_bg_id
                })
            except Exception as e:
                print(f"Skipping bad book {book.get('id')}: {e}")
                continue
            
        # Slice to limit if we fetched extra
        if len(books_data) > limit:
            books_data = books_data[:limit]

        return jsonify({
            "isSubscribed": True,
            "books": books_data,
            "hasMore": len(books_result) > limit,
            "savedOffset": saved_offset
        }), 200
        
    except Exception as e:
        print(f"Error in get_reels: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/reels/offset', methods=['GET'])
def get_reels_offset():
    """Get the saved reels offset for a user."""
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"error": "User ID is required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if column exists (graceful handling if migration missing?)
        # For now, just query. If it fails, return 0.
        query = "SELECT reels_offset FROM users WHERE id = %s"
        try:
            result = db.execute_query(query, (user_id,))
            offset = result[0]['reels_offset'] if result and result[0]['reels_offset'] is not None else 0
            return jsonify({"offset": offset}), 200
        except Exception as e:
             # Column likely missing
             print(f"Error getting offset (col missing?): {e}")
             return jsonify({"offset": 0}), 200
             
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/reels/offset', methods=['POST'])
def update_reels_offset():
    """Update the saved reels offset for a user."""
    data = request.json
    user_id = data.get('user_id')
    offset = data.get('offset')

    if not user_id or offset is None:
        return jsonify({"error": "User ID and offset are required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Validate offset against total books count
        count_query = "SELECT COUNT(*) as count FROM books"
        count_result = db.execute_query(count_query)
        total_books = count_result[0]['count'] if count_result else 0
        
        # If offset is beyond total books, reset to 0 (loop)
        # Also, if offset is exactly equal to total, it means we are at the end, so next fetch would be empty -> reset to 0.
        final_offset = offset
        if offset >= total_books:
            final_offset = 0

        query = "UPDATE users SET reels_offset = %s WHERE id = %s"
        db.execute_query(query, (final_offset, user_id))
        return jsonify({"message": "Offset updated", "final_offset": final_offset}), 200
    except Exception as e:
        # If it fails (e.g. column missing), we log but maybe don't crash client?
        print(f"Error updating offset: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# ===================== COMBINED LIBRARY ENDPOINT =====================
@app.route('/library', methods=['GET'])
@jwt_required
def get_library():
    """
    Combined endpoint that returns all data needed for the library screen in one call:
    - allBooks: all books with favorites marked
    - purchasedIds: list of book IDs the user has access to
    - listenHistory: books with progress data
    - uploadedBooks: books uploaded by this user (if admin)
    - isSubscribed: subscription status
    """
    import time
    start_total = time.time()
    
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        user_id = request.args.get('user_id', type=int)
        
        # Check cache
        cache_key = f"library:{user_id}" if user_id else "library:anon"
        cached_data = cache.get(cache_key)
        if cached_data:
            return jsonify(cached_data)

        # Get subscription status
        is_subscribed = is_subscriber(user_id, db) if user_id else False
        
        # Get all books (with user preference for BG music)
        # Uses JOINs instead of correlated subqueries for better performance
        books_query = """
            SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, b.duration_seconds,
                   b.premium, b.pdf_path,
                   COALESCE(ub.background_music_id, b.background_music_id) as background_music_id,
                   c.slug as category_slug,
                   COALESCE(pi_count.cnt, 0) as playlist_count,
                   br_stats.avg_rating as average_rating,
                   COALESCE(br_stats.rating_cnt, 0) as rating_count
            FROM books b
            LEFT JOIN categories c ON b.primary_category_id = c.id
            LEFT JOIN user_books ub ON ub.book_id = b.id AND ub.user_id = %s
            LEFT JOIN (
                SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id
            ) pi_count ON pi_count.book_id = b.id
            LEFT JOIN (
                SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id
            ) br_stats ON br_stats.book_id = b.id
            ORDER BY b.id DESC
        """
        all_books_result = db.execute_query(books_query, (user_id,))
        
        # Get favorites
        favIds = []
        if user_id:
            fav_result = db.execute_query("SELECT book_id FROM favorites WHERE user_id = %s", (user_id,))
            if fav_result:
                favIds = [row['book_id'] for row in fav_result]
        
        # Get purchased/accessible book IDs
        purchased_ids = []
        if user_id:
            if is_subscribed:
                # Subscriber gets all books
                purchased_ids = [str(row['id']) for row in all_books_result] if all_books_result else []
            else:
                # Non-subscriber: only their purchased books
                purchased_result = db.execute_query(
                    "SELECT book_id FROM user_books WHERE user_id = %s", (user_id,)
                )
                if purchased_result:
                    purchased_ids = [str(row['book_id']) for row in purchased_result]
        
        # Get listen history with progress
        listen_history = []
        if user_id:
            history_query = """
                SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, b.duration_seconds,
                       b.premium, b.pdf_path,
                       COALESCE(ub.background_music_id, b.background_music_id) as background_music_id,
                       c.slug as category_slug,
                       ub.last_played_position_seconds as last_position,
                       ub.last_accessed_at,
                       ub.current_playlist_item_id,
                       COALESCE(pi_count.cnt, 0) as playlist_count,
                       br_stats.avg_rating as average_rating,
                       COALESCE(br_stats.rating_cnt, 0) as rating_count
                FROM user_books ub
                JOIN books b ON ub.book_id = b.id
                LEFT JOIN categories c ON b.primary_category_id = c.id
                LEFT JOIN (
                    SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id
                ) pi_count ON pi_count.book_id = b.id
                LEFT JOIN (
                    SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id
                ) br_stats ON br_stats.book_id = b.id
                WHERE ub.user_id = %s AND ub.last_played_position_seconds > 0 AND (ub.is_read = 0 OR ub.is_read IS NULL)
                ORDER BY ub.last_accessed_at DESC
            """
            history_result = db.execute_query(history_query, (user_id,))
            if history_result:
                for book in history_result:
                    cover_path, cover_thumb = resolve_cover_urls(book['cover_image_path'])
                    audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")
                    listen_history.append({
                        "id": str(book['id']),
                        "title": book['title'],
                        "author": book['author'],
                        "audioUrl": audio_path,
                        "coverUrl": cover_path,
                        "coverThumbnailUrl": cover_thumb,
                        "categoryId": book['category_slug'] or "others",
                        "durationSeconds": book['duration_seconds'],
                        "lastPosition": book['last_position'],
                        "premium": bool(book.get('premium', False)),
                        "averageRating": float(book['average_rating']) if book['average_rating'] else 0.0,
                        "ratingCount": book['rating_count'] or 0,
                        "isFavorite": book['id'] in favIds,
                        "isFavorite": book['id'] in favIds,
                        "isPlaylist": book['playlist_count'] > 0,
                        "backgroundMusicId": book.get('background_music_id'),
                        "currentPlaylistItemId": book.get('current_playlist_item_id'),
                    })
        
        # Get uploaded books (for admin users)
        uploaded_books = []
        if user_id:
            upload_query = """
                SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, b.duration_seconds,
                       b.premium, b.pdf_path, b.background_music_id, c.slug as category_slug,
                       COALESCE(pi_count.cnt, 0) as playlist_count,
                       br_stats.avg_rating as average_rating,
                       COALESCE(br_stats.rating_cnt, 0) as rating_count
                FROM books b
                LEFT JOIN categories c ON b.primary_category_id = c.id
                LEFT JOIN (
                    SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id
                ) pi_count ON pi_count.book_id = b.id
                LEFT JOIN (
                    SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id
                ) br_stats ON br_stats.book_id = b.id
                WHERE b.posted_by_user_id = %s
                ORDER BY b.id DESC
            """
            upload_result = db.execute_query(upload_query, (user_id,))
            if upload_result:
                for book in upload_result:
                    cover_path, cover_thumb = resolve_cover_urls(book['cover_image_path'])
                    audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")
                    uploaded_books.append({
                        "id": str(book['id']),
                        "title": book['title'],
                        "author": book['author'],
                        "audioUrl": audio_path,
                        "coverUrl": cover_path,
                        "coverThumbnailUrl": cover_thumb,
                        "categoryId": book['category_slug'] or "others",
                        "durationSeconds": book['duration_seconds'],
                        "premium": bool(book.get('premium', False)),
                        "averageRating": float(book['average_rating']) if book['average_rating'] else 0.0,
                        "ratingCount": book['rating_count'] or 0,
                        "isFavorite": book['id'] in favIds,
                        "isPlaylist": book['playlist_count'] > 0,
                        "postedByUserId": str(user_id),
                        "backgroundMusicId": book.get('background_music_id'),
                    })
        
        # Build all books response
        all_books = []
        if all_books_result:
            for book in all_books_result:
                cover_path, cover_thumb = resolve_cover_urls(book['cover_image_path'])
                audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")
                all_books.append({
                    "id": str(book['id']),
                    "title": book['title'],
                    "author": book['author'],
                    "audioUrl": audio_path,
                    "coverUrl": cover_path,
                    "coverThumbnailUrl": cover_thumb,
                    "categoryId": book['category_slug'] or "others",
                    "durationSeconds": book['duration_seconds'],
                    "premium": bool(book.get('premium', False)),
                    "averageRating": float(book['average_rating']) if book['average_rating'] else 0.0,
                    "ratingCount": book['rating_count'] or 0,
                    "isFavorite": book['id'] in favIds,
                    "isPlaylist": book['playlist_count'] > 0,
                    "backgroundMusicId": book.get('background_music_id'),
                })
        
        response = {
            "allBooks": all_books,
            "purchasedIds": purchased_ids,
            "favoriteIds": favIds,
            "listenHistory": listen_history,
            "uploadedBooks": uploaded_books,
            "isSubscribed": is_subscribed,
        }
        
        print(f"[TIMING] get_library: total={round((time.time() - start_total) * 1000)}ms")
        
        cache.set(cache_key, response, 30)
        
        return jsonify(response)
        
    except Exception as e:
        print(f"Error in get_library: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/user-books/<int:user_id>', methods=['GET'])
@jwt_required
def get_user_books(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if user has active subscription
        if is_subscriber(user_id, db):
            # Subscriber gets access to ALL books
            all_books_query = "SELECT id FROM books"
            all_books = db.execute_query(all_books_query)
            book_ids = [row['id'] for row in all_books] if all_books else []
            return jsonify(book_ids)

        # Non-subscriber: return only legacy purchased books
        query = "SELECT book_id FROM user_books WHERE user_id = %s"
        result = db.execute_query(query, (user_id,))

        book_ids = [row['book_id'] for row in result] if result else []
        return jsonify(book_ids)

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/buy-book', methods=['POST'])
@jwt_required
def buy_book():
    """
    Now used for adding book to user's library (for progress tracking).
    For subscribers: Creates tracking entry without payment.
    For non-subscribers: Returns error suggesting subscription.
    """
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Check if user has active subscription
        if not is_subscriber(user_id, db):
            return jsonify({
                "error": "subscription_required",
                "message": "Please subscribe to access books"
            }), 403

        # Check if already in library
        check_query = "SELECT id FROM user_books WHERE user_id = %s AND book_id = %s"
        existing = db.execute_query(check_query, (user_id, book_id))

        if existing:
            return jsonify({"message": "Book already in library"}), 200

        # Insert tracking entry (no payment since subscribed)
        insert_query = "INSERT INTO user_books (user_id, book_id) VALUES (%s, %s)"
        db.execute_query(insert_query, (user_id, book_id))

        new_badges = []
        try:
            # Check for new badges
            badge_service = BadgeService(db.connection)
            new_badges = badge_service.check_badges(user_id)
        except Exception as e:
            print(f"Error checking badges in buy_book: {e}")
            import traceback
            traceback.print_exc()

        return jsonify({"message": "Book added to library", "new_badges": new_badges}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/complete-track', methods=['POST'])
@jwt_required
def complete_track():
    data = request.get_json()
    user_id = data.get('user_id')
    track_id = data.get('track_id')
    
    if not all([user_id, track_id]):
        return jsonify({"error": "Missing user_id or track_id"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # 1. Mark track as completed
        query = "INSERT INTO user_completed_tracks (user_id, track_id) VALUES (%s, %s) ON CONFLICT (user_id, track_id) DO NOTHING"
        db.execute_query(query, (user_id, track_id))
        
        # 2. Check if ALL tracks for this book are completed
        # First get book_id
        book_query = "SELECT book_id FROM playlist_items WHERE id = %s"
        book_res = db.execute_query(book_query, (track_id,))
        
        is_book_completed = False
        if book_res:
            book_id = book_res[0]['book_id']
            
            # Count total tracks
            count_query = "SELECT COUNT(*) as total FROM playlist_items WHERE book_id = %s"
            total_tracks = db.execute_query(count_query, (book_id,))[0]['total']
            
            # Count completed tracks for this user & book
            completed_query = """
                SELECT COUNT(*) as completed 
                FROM user_completed_tracks uct
                JOIN playlist_items pi ON uct.track_id = pi.id
                WHERE uct.user_id = %s AND pi.book_id = %s
            """
            completed_tracks = db.execute_query(completed_query, (user_id, book_id))[0]['completed']
            
            if completed_tracks >= total_tracks:
                print(f"User {user_id} completed all {completed_tracks} tracks for book {book_id}")

                # Check if all quizzes are passed before marking book as complete
                # 1. Check book-level quiz
                book_quiz_query = """
                    SELECT q.id FROM quizzes q
                    WHERE q.book_id = %s AND q.playlist_item_id IS NULL
                """
                book_quiz = db.execute_query(book_quiz_query, (book_id,))

                book_quiz_passed = True
                if book_quiz and len(book_quiz) > 0:
                    quiz_id = book_quiz[0]['id']
                    passed_query = """
                        SELECT is_passed FROM user_quiz_results
                        WHERE user_id = %s AND quiz_id = %s AND is_passed = 1
                        LIMIT 1
                    """
                    passed_res = db.execute_query(passed_query, (user_id, quiz_id))
                    book_quiz_passed = bool(passed_res)

                # 2. Check all track-level quizzes
                track_quizzes_query = """
                    SELECT q.id, q.playlist_item_id FROM quizzes q
                    WHERE q.book_id = %s AND q.playlist_item_id IS NOT NULL
                """
                track_quizzes = db.execute_query(track_quizzes_query, (book_id,))

                all_track_quizzes_passed = True
                if track_quizzes and len(track_quizzes) > 0:
                    for tq in track_quizzes:
                        passed_query = """
                            SELECT is_passed FROM user_quiz_results
                            WHERE user_id = %s AND quiz_id = %s AND is_passed = 1
                            LIMIT 1
                        """
                        passed_res = db.execute_query(passed_query, (user_id, tq['id']))
                        if not passed_res:
                            all_track_quizzes_passed = False
                            break

                # Only mark book as complete if all quizzes are passed
                if book_quiz_passed and all_track_quizzes_passed:
                    is_book_completed = True
                    print(f"User {user_id} fully completed book {book_id} (all tracks + all quizzes)")

                    # Mark book as read
                    update_read = "UPDATE user_books SET is_read = 1, last_accessed_at = CURRENT_TIMESTAMP WHERE user_id = %s AND book_id = %s"
                    db.execute_query(update_read, (user_id, book_id))

                    # Check Badges (since book is now read)
                    try:
                        badge_service = BadgeService(db.connection)
                        new_badges_list = badge_service.check_badges(user_id)
                        return jsonify({"message": "Track marked as completed", "is_book_completed": is_book_completed, "new_badges": new_badges_list}), 200
                    except Exception as b_err:
                        print(f"Badge check error: {b_err}")
                else:
                    print(f"User {user_id} has pending quizzes for book {book_id} (book_quiz_passed={book_quiz_passed}, track_quizzes_passed={all_track_quizzes_passed})")

        return jsonify({"message": "Track marked as completed", "is_book_completed": is_book_completed, "new_badges": []}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/update-progress', methods=['POST'])
@jwt_required
def update_progress():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')
    position = data.get('position_seconds')
    total_duration = data.get('duration') # Optional, from player
    playlist_item_id = data.get('playlist_item_id') # Optional, for track progress

    if not all([user_id, book_id, position is not None]):
        return jsonify({"error": "Missing fields"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        check_query = "SELECT id FROM user_books WHERE user_id = %s AND book_id = %s"
        existing = db.execute_query(check_query, (user_id, book_id))

        # Auto-add book to library if user is subscriber but book not in user_books
        if not existing and is_subscriber(user_id, db):
            insert_query = "INSERT INTO user_books (user_id, book_id) VALUES (%s, %s)"
            db.execute_query(insert_query, (user_id, book_id))
            existing = True  # Now it exists
            print(f"Auto-added book {book_id} to library for subscriber user {user_id}")

        if existing:
            # Duration Logic
            duration_query = "SELECT duration_seconds FROM books WHERE id = %s"
            duration_result = db.execute_query(duration_query, (book_id,))
            db_duration = duration_result[0]['duration_seconds'] if duration_result else 0
            
            if db_duration == 0 and total_duration and total_duration > 0:
                # Only update duration if it's NOT a playlist (playlists usually have 0 or sum)
                # For now we let it update, but we won't use it for is_read if it's a playlist
                print(f"Updating duration for book {book_id} to {total_duration}")
                update_book_query = "UPDATE books SET duration_seconds = %s WHERE id = %s"
                db.execute_query(update_book_query, (total_duration, book_id))
                db_duration = total_duration

            # Check if Playlist
            count_pl_query = "SELECT COUNT(*) as c FROM playlist_items WHERE book_id = %s"
            is_playlist = db.execute_query(count_pl_query, (book_id,))[0]['c'] > 0

            # Completion Check (95% rule) - ONLY for non-playlists
            # Playlists are marked read only via /complete-track when all items are done
            is_read = False
            if not is_playlist and db_duration > 0 and position >= (db_duration * 0.95):
                is_read = True
            
            # Update user_books
            update_sql = "UPDATE user_books SET last_played_position_seconds = %s, last_accessed_at = CURRENT_TIMESTAMP"
            params = [position]
            
            if is_read:
                update_sql += ", is_read = 1"
            
            if playlist_item_id:
                update_sql += ", current_playlist_item_id = %s"
                params.append(playlist_item_id)

            update_sql += " WHERE user_id = %s AND book_id = %s"
            params.extend([user_id, book_id])
            
            db.execute_query(update_sql, tuple(params))
            
            if playlist_item_id:
                track_upd_query = """
                    INSERT INTO user_track_progress (user_id, book_id, playlist_item_id, position_seconds)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (user_id, book_id, playlist_item_id) DO UPDATE SET 
                        position_seconds = EXCLUDED.position_seconds, 
                        updated_at = CURRENT_TIMESTAMP
                """
                db.execute_query(track_upd_query, (user_id, book_id, playlist_item_id, position))

            
            # Log to playback_history (History Log)
            # Use INSERT ON DUPLICATE KEY UPDATE to ensure only one record per user/book/playlist_item
            # Skip updating if track is completed (optimization)
            
            # First check if this track/book is already completed
            should_update = True
            if playlist_item_id:
                # Check if track is completed
                completed_check = "SELECT id FROM user_completed_tracks WHERE user_id = %s AND track_id = %s"
                completed_res = db.execute_query(completed_check, (user_id, playlist_item_id))
                if completed_res:
                    should_update = False
                    print(f"Track {playlist_item_id} already completed, skipping playback_history update")
            
            if should_update:
                # Use INSERT ON CONFLICT to maintain only one record per combination
                history_query = """
                    INSERT INTO playback_history (user_id, book_id, playlist_item_id, start_time, end_time, played_seconds)
                    VALUES (%s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, %s)
                    ON CONFLICT (user_id, book_id, playlist_item_id) DO UPDATE SET 
                        end_time = CURRENT_TIMESTAMP,
                        played_seconds = EXCLUDED.played_seconds
                """
                db.execute_query(history_query, (user_id, book_id, playlist_item_id, position))
            
            # Check for new badges
            badge_service = BadgeService(db.connection)
            new_badges = badge_service.check_badges(user_id)
            
            return jsonify({"message": "Progress updated", "is_read": is_read, "new_badges": new_badges}), 200
        else:
            return jsonify({"error": "Book not found in library"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/register-download', methods=['POST'])
def register_download():
    data = request.json
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not user_id or not book_id:
        return jsonify({'error': 'Missing user_id or book_id'}), 400

    db = Database()
    try:
        # Insert or update timestamp
        # Using ON CONFLICT to refresh timestamp on re-download
        query = """
        INSERT INTO user_downloads (user_id, book_id, downloaded_at)
        VALUES (%s, %s, CURRENT_TIMESTAMP)
        ON CONFLICT (user_id, book_id) DO UPDATE SET downloaded_at = CURRENT_TIMESTAMP
        """
        db.execute_query(query, (user_id, book_id))
        return jsonify({'success': True, 'message': 'Download registered'}), 200
    except Exception as e:
        print(f"Error registering download: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        db.disconnect()

@app.route('/user-stats/<int:user_id>', methods=['GET'])
@jwt_required
def get_user_stats(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Get all user's books
        books_query = """
            SELECT b.id, b.duration_seconds,
                   (SELECT COUNT(*) FROM playlist_items WHERE book_id = b.id) as playlist_count
            FROM user_books ub
            JOIN books b ON ub.book_id = b.id
            WHERE ub.user_id = %s
        """
        books_result = db.execute_query(books_query, (user_id,))
        
        total_seconds = 0
        completed_count = 0
        
        if books_result:
            for book in books_result:
                book_id = book['id']
                is_playlist = book['playlist_count'] > 0
                total_duration = book['duration_seconds'] or 0
                
                # Calculate listen time using same logic as listen_history
                if is_playlist:
                    playlist_progress_query = """
                        SELECT 
                            pi.id as playlist_item_id,
                            pi.duration_seconds,
                            COALESCE(MAX(ph.played_seconds), 0) as last_position,
                            (SELECT COUNT(*) FROM user_completed_tracks WHERE user_id = %s AND track_id = pi.id) as is_completed
                        FROM playlist_items pi
                        LEFT JOIN playback_history ph ON ph.playlist_item_id = pi.id AND ph.user_id = %s
                        WHERE pi.book_id = %s
                        GROUP BY pi.id, pi.duration_seconds
                    """
                    tracks_result = db.execute_query(playlist_progress_query, (user_id, user_id, book_id))
                    
                    book_listened_seconds = 0
                    if tracks_result:
                        for track in tracks_result:
                            track_duration = track['duration_seconds'] or 0
                            is_completed = track['is_completed'] > 0
                            
                            if is_completed and track_duration > 0:
                                listened = track_duration
                            else:
                                last_pos = track['last_position'] or 0
                                listened = min(last_pos, track_duration) if track_duration > 0 else last_pos
                            
                            book_listened_seconds += listened
                    
                    total_seconds += book_listened_seconds
                    
                    # Check if book is completed (all tracks at 100%)
                    if total_duration > 0 and book_listened_seconds >= total_duration:
                        completed_count += 1
                else:
                    # Single file
                    single_progress_query = """
                        SELECT COALESCE(MAX(played_seconds), 0) as last_position
                        FROM playback_history
                        WHERE user_id = %s AND book_id = %s
                    """
                    single_result = db.execute_query(single_progress_query, (user_id, book_id))
                    if single_result:
                        listened = single_result[0]['last_position'] or 0
                        total_seconds += listened
                        
                        # Check if completed (95% threshold)
                        if total_duration > 0 and listened >= (total_duration * 0.95):
                            completed_count += 1
        
        return jsonify({
            "total_listening_time_seconds": total_seconds,
            "books_completed": completed_count
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()



@app.route('/listen-history/<int:user_id>', methods=['GET'])
@jwt_required
def get_listen_history(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Get all books the user has accessed
        books_query = """
            SELECT DISTINCT b.id, b.title, b.author, b.audio_path, b.cover_image_path,
                   c.slug as category_slug, b.duration_seconds, ub.last_accessed_at,
                   b.premium,
                   (SELECT AVG(stars) FROM book_ratings WHERE book_id = b.id) as average_rating,
                   (SELECT COUNT(*) FROM book_ratings WHERE book_id = b.id) as rating_count,
                   (SELECT COUNT(*) FROM playlist_items WHERE book_id = b.id) as playlist_count
            FROM user_books ub
            JOIN books b ON ub.book_id = b.id
            LEFT JOIN categories c ON b.primary_category_id = c.id
            WHERE ub.user_id = %s AND ub.last_played_position_seconds > 0
            ORDER BY ub.last_accessed_at DESC
        """
        books_result = db.execute_query(books_query, (user_id,))
        
        history = []
        if books_result:
            for book in books_result:
                book_id = book['id']
                is_playlist = book['playlist_count'] > 0
                
                # Calculate total listen time based on playback_history
                total_listened_seconds = 0
                
                if is_playlist:
                    # For playlists: get the last (MAX) position for each track
                    # For completed tracks, use full duration instead
                    playlist_progress_query = """
                        SELECT 
                            pi.id as playlist_item_id,
                            pi.duration_seconds,
                            COALESCE(MAX(ph.played_seconds), 0) as last_position,
                            (SELECT COUNT(*) FROM user_completed_tracks WHERE user_id = %s AND track_id = pi.id) as is_completed
                        FROM playlist_items pi
                        LEFT JOIN playback_history ph ON ph.playlist_item_id = pi.id AND ph.user_id = %s
                        WHERE pi.book_id = %s
                        GROUP BY pi.id, pi.duration_seconds
                    """
                    tracks_result = db.execute_query(playlist_progress_query, (user_id, user_id, book_id))
                    
                    if tracks_result:
                        # Sum the last position of each track to get total listen time
                        # For completed tracks, use full duration
                        for track in tracks_result:
                            track_duration = track['duration_seconds'] or 0
                            is_completed = track['is_completed'] > 0
                            
                            if is_completed and track_duration > 0:
                                # Track is completed - use full duration
                                listened = track_duration
                            else:
                                # Track not completed - use last recorded position
                                last_pos = track['last_position'] or 0
                                # Use the minimum of last_position and duration to avoid over-counting
                                listened = min(last_pos, track_duration) if track_duration > 0 else last_pos
                            
                            total_listened_seconds += listened
                else:
                    # For single files: get the MAX position from playback_history
                    single_progress_query = """
                        SELECT COALESCE(MAX(played_seconds), 0) as last_position
                        FROM playback_history
                        WHERE user_id = %s AND book_id = %s
                    """
                    single_result = db.execute_query(single_progress_query, (user_id, book_id))
                    if single_result:
                        total_listened_seconds = single_result[0]['last_position'] or 0
                
                # Resolve cover URL and thumbnail (handles R2 and local)
                cover_path, cover_thumbnail_path = resolve_cover_urls(book['cover_image_path'])

                # Resolve audio URL (handles R2 refs, http, and relative paths)
                audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")

                # Calculate percentage
                total_duration = book['duration_seconds'] or 0
                percentage = (total_listened_seconds / total_duration * 100) if total_duration > 0 else 0

                history.append({
                    "id": str(book_id),
                    "title": book['title'],
                    "author": book['author'],
                    "audioUrl": audio_path,
                    "coverUrl": cover_path,
                    "coverUrlThumbnail": cover_thumbnail_path,
                    "categoryId": book['category_slug'] or "",
                    "lastPosition": int(total_listened_seconds),
                    "duration": total_duration,
                    "percentage": round(percentage, 2),
                    "lastAccessed": str(book['last_accessed_at']),
                    "averageRating": float(book['average_rating'] or 0),
                    "ratingCount": int(book['rating_count'] or 0),
                    "premium": bool(book['premium'])
                })
                
        return jsonify(history)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/book-status/<int:user_id>/<int:book_id>', methods=['GET'])
@jwt_required
def get_book_status(user_id, book_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        playlist_item_id = request.args.get('playlist_item_id')
        
        # 1. Fetch Global Book Status first (to get default background music)
        query_book = """
            SELECT 
                COALESCE(ub.last_played_position_seconds, 0) as last_played_position_seconds, 
                ub.current_playlist_item_id, 
                COALESCE(ub.background_music_id, b.background_music_id) as background_music_id
            FROM books b
            LEFT JOIN user_books ub ON ub.book_id = b.id AND ub.user_id = %s
            WHERE b.id = %s
        """
        result_book = db.execute_query(query_book, (user_id, book_id))
        
        # Prepare response with book-level defaults
        response_data = {
            "position_seconds": 0,
            "current_playlist_item_id": None,
            "background_music_id": None
        }

        if result_book:
            response_data["position_seconds"] = result_book[0]['last_played_position_seconds'] or 0
            response_data["current_playlist_item_id"] = result_book[0].get('current_playlist_item_id')
            response_data["background_music_id"] = result_book[0].get('background_music_id')

        # 2. If track specific, override position
        if playlist_item_id:
            query_track = "SELECT position_seconds FROM user_track_progress WHERE user_id = %s AND playlist_item_id = %s"
            result_track = db.execute_query(query_track, (user_id, playlist_item_id))
            if result_track:
                 response_data["position_seconds"] = result_track[0]['position_seconds']
            else:
                 response_data["position_seconds"] = 0
            
            
        return jsonify(response_data), 200
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/user-books/background-music', methods=['POST'])
@jwt_required
def update_user_background_music():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')
    bg_music_id = data.get('background_music_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Upsert user_books record
        # Note: This assumes there is a UNIQUE constraint on (user_id, book_id) in user_books.
        # If not, we might get duplicates or errors, but standard join tables usually have it.
        # We'll use ON CONFLICT DO UPDATE.
        
        # First ensure the record exists or create it, then update.
        # Actually standard INSERT ON CONFLICT handle creation.
        
        # We also need to be careful if the user hasn't "started" the book yet?
        # Usually user_books implies opened/purchased. 
        # If it doesn't exist, we insert it.
        
        query = """
            INSERT INTO user_books (user_id, book_id, background_music_id, last_accessed_at)
            VALUES (%s, %s, %s, NOW())
            ON CONFLICT (user_id, book_id)
            DO UPDATE SET background_music_id = EXCLUDED.background_music_id, last_accessed_at = NOW()
        """
        db.execute_query(query, (user_id, book_id, bg_music_id))
        
        return jsonify({"message": "Background music preference updated"}), 200
    except Exception as e:
        print(f"Error updating background music: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "message": "Audiobooks API is running"})

@app.route('/badges/<int:user_id>', methods=['GET'])
@jwt_required
def get_user_badges(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        badge_service = BadgeService(db.connection)
        badges = badge_service.get_all_badges_with_progress(user_id)
        return jsonify(badges)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/favorites', methods=['POST'])
def add_favorite():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        query = "INSERT INTO favorites (user_id, book_id) VALUES (%s, %s) ON CONFLICT (user_id, book_id) DO NOTHING"
        db.execute_query(query, (user_id, book_id))
        return jsonify({"message": "Added to favorites"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/favorites', methods=['DELETE'])
def remove_favorite():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')

    if not all([user_id, book_id]):
        return jsonify({"error": "Missing user_id or book_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        query = "DELETE FROM favorites WHERE user_id = %s AND book_id = %s"
        db.execute_query(query, (user_id, book_id))
        return jsonify({"message": "Removed from favorites"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/favorites/<int:user_id>', methods=['GET'])
@jwt_required
def get_favorites(user_id):
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Use a JOIN to optionally ensure books exist if we went with No FK
        query = "SELECT book_id FROM favorites WHERE user_id = %s"
        results = db.execute_query(query, (user_id,))
        favorites = [row['book_id'] for row in results]
        return jsonify(favorites), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/upload_book', methods=['POST'])
@jwt_required
def upload_book():
    try:
        title = request.form.get('title')
        author = request.form.get('author')
        category_id = request.form.get('category_id')
        user_id = request.form.get('user_id')
        description = request.form.get('description', '')
        price = request.form.get('price', 0.0)
        is_premium = request.form.get('is_premium', '0')  # Default to 0 (not premium)
        background_music_id = request.form.get('background_music_id') # Optional background music ID

        if not all([title, author, category_id, user_id]):
             return jsonify({"error": "Missing required fields"}), 400

        # Lookup numeric Category ID
        cat_query = "SELECT id FROM categories WHERE slug = %s"
        db = Database()
        if not db.connect():
             return jsonify({"error": "Database error"}), 500

        # Admin check - only admin can upload books
        if not is_admin_user(user_id, db):
            db.disconnect()
            return jsonify({"error": "Upload feature is restricted to admin users"}), 403
        
        cats = db.execute_query(cat_query, (category_id,))
        if not cats:
             if category_id.isdigit():
                 numeric_cat_id = int(category_id)
             else:
                 return jsonify({"error": f"Invalid category: {category_id}"}), 400
        else:
            numeric_cat_id = cats[0]['id']

        # Check for files
        audio_files = request.files.getlist('audio')
        if not audio_files or (len(audio_files) == 1 and audio_files[0].filename == ''):
            db.disconnect()
            return jsonify({"error": "No audio files provided"}), 400

        # Cover photo is mandatory
        if 'cover' not in request.files or request.files['cover'].filename == '':
            db.disconnect()
            return jsonify({"error": "Cover photo is required"}), 400

        # Base directories
        base_dir = os.path.dirname(os.path.abspath(__file__))
        static_dir = os.path.join(base_dir, 'static')
        
        # Audio Path & Playlist Logic
        # If 1 file -> Standard behavior (save to AudioBooks/filename)
        # If >1 file -> Playlist behavior (save to AudioBooks/timestamp_title/filename)
        
        is_playlist = len(audio_files) > 1
        
        main_audio_path = "" # For books table (first file or empty?)
        # Strategy: 
        # If Playlist: main_audio_path can be null or point to first file as fallback.
        # Let's verify schema: audio_path is VARCHAR, maybe Not Null? 
        # Usually it is allowed to be empty if we relax it, but let's point to first track.
        
        timestamp_prefix = int(datetime.datetime.now().timestamp())
        
        saved_files_info = [] # (filename, full_db_path)

        # Create a temp directory for processing (duration extraction etc.)
        temp_dir = tempfile.mkdtemp()

        try:  # Inner try for temp dir cleanup
            if is_playlist:
                safe_title = secure_filename(title)
                folder_name = f"{timestamp_prefix}_{safe_title}"

                for index, file in enumerate(audio_files):
                    if file.filename == '': continue

                    safe_fname = secure_filename(f"{index+1:02d}_{file.filename}")

                    # Save to temp for duration extraction
                    temp_path = os.path.join(temp_dir, safe_fname)
                    file.save(temp_path)

                    # Extract duration using mutagen
                    duration_seconds = 0
                    try:
                        audio_info = MutagenFile(temp_path)
                        if audio_info and hasattr(audio_info.info, 'length'):
                            duration_seconds = int(audio_info.info.length)
                            print(f"Extracted duration for {safe_fname}: {duration_seconds}s")
                    except Exception as e:
                        print(f"Could not extract duration for {safe_fname}: {e}")
                    
                    # Fallback for WAV files if mutagen failed or returned 0
                    if duration_seconds == 0 and safe_fname.lower().endswith('.wav'):
                        try:
                            with wave.open(temp_path, 'r') as f:
                                frames = f.getnframes()
                                rate = f.getframerate()
                                duration_seconds = int(frames / float(rate))
                                print(f"Extracted WAV duration via wave for {safe_fname}: {duration_seconds}s")
                        except Exception as e:
                            print(f"Could not extract WAV duration for {safe_fname}: {e}")

                    # Try R2 upload, fallback to local
                    r2_key = f"AudioBooks/{folder_name}/{safe_fname}"
                    r2_url = upload_local_file_to_r2(temp_path, r2_key)

                    if r2_url:
                        full_url = r2_url
                    else:
                        # Fallback: move to local static dir
                        local_folder = os.path.join(static_dir, "AudioBooks", folder_name)
                        os.makedirs(local_folder, exist_ok=True)
                        shutil.copy2(temp_path, os.path.join(local_folder, safe_fname))
                        full_url = f"{BASE_URL}static/AudioBooks/{folder_name}/{safe_fname}"

                    saved_files_info.append({
                        "path": full_url,
                        "title": file.filename,
                        "order": index,
                        "duration": duration_seconds
                    })

                main_audio_path = saved_files_info[0]["path"] if saved_files_info else ""

            else:
                # Single File
                audio_file = audio_files[0]
                audio_filename = secure_filename(f"{timestamp_prefix}_{audio_file.filename}")

                # Save to temp for duration extraction
                temp_path = os.path.join(temp_dir, audio_filename)
                audio_file.save(temp_path)

                # Extract duration
                duration_seconds = 0
                try:
                    audio_info = MutagenFile(temp_path)
                    if audio_info and hasattr(audio_info.info, 'length'):
                        duration_seconds = int(audio_info.info.length)
                        print(f"Extracted duration for single file: {duration_seconds}s")
                except Exception as e:
                    print(f"Could not extract duration for single file: {e}")

                # Fallback for WAV files if mutagen failed or returned 0
                if duration_seconds == 0 and audio_filename.lower().endswith('.wav'):
                    try:
                        with wave.open(temp_path, 'r') as f:
                            frames = f.getnframes()
                            rate = f.getframerate()
                            duration_seconds = int(frames / float(rate))
                            print(f"Extracted WAV duration via wave for single file: {duration_seconds}s")
                    except Exception as e:
                        print(f"Could not extract WAV duration for single file: {e}")

                # Try R2 upload, fallback to local
                r2_key = f"AudioBooks/{audio_filename}"
                r2_url = upload_local_file_to_r2(temp_path, r2_key)

                if r2_url:
                    main_audio_path = r2_url
                else:
                    local_path = os.path.join(static_dir, "AudioBooks", audio_filename)
                    os.makedirs(os.path.dirname(local_path), exist_ok=True)
                    shutil.copy2(temp_path, local_path)
                    main_audio_path = f"{BASE_URL}static/AudioBooks/{audio_filename}"

                saved_files_info.append({"path": main_audio_path, "title": audio_file.filename, "order": 0, "duration": duration_seconds})

            # Handle Cover
            db_cover_path = None
            if 'cover' in request.files:
                cover_file = request.files['cover']
                if cover_file.filename != '':
                    cover_filename = secure_filename(f"{timestamp_prefix}_{cover_file.filename}")

                    # Save to temp for thumbnail generation
                    temp_cover_path = os.path.join(temp_dir, cover_filename)
                    cover_file.save(temp_cover_path)

                    # Try R2 upload for cover
                    r2_key = f"BookCovers/{cover_filename}"
                    r2_url = upload_local_file_to_r2(temp_cover_path, r2_key)

                    if r2_url:
                        db_cover_path = r2_url

                        # Generate thumbnail and upload to R2
                        temp_thumb_path = os.path.join(temp_dir, f"thumb_{cover_filename}")
                        try:
                            create_thumbnail(temp_cover_path, temp_thumb_path, size=(200, 200))
                            thumb_r2_key = f"BookCovers/thumbnails/{cover_filename}"
                            upload_local_file_to_r2(temp_thumb_path, thumb_r2_key)
                        except Exception as e:
                            print(f"Thumbnail generation/upload failed: {e}")
                    else:
                        # Fallback: save locally
                        local_cover_path = os.path.join(static_dir, "BookCovers", cover_filename)
                        os.makedirs(os.path.dirname(local_cover_path), exist_ok=True)
                        shutil.copy2(temp_cover_path, local_cover_path)
                        db_cover_path = f"{BASE_URL}static/BookCovers/{cover_filename}"

            # Handle PDF (Optional)
            db_pdf_path = None
            if 'pdf' in request.files:
                pdf_file = request.files['pdf']
                if pdf_file.filename != '':
                    if is_playlist:
                        safe_title = secure_filename(title)
                        folder_name = f"{timestamp_prefix}_{safe_title}"
                        pdf_r2_key = f"AudioBooks/{folder_name}/book.pdf"
                        pdf_local_subpath = f"AudioBooks/{folder_name}/book.pdf"
                    else:
                        pdf_fname = secure_filename(f"{timestamp_prefix}_book.pdf")
                        pdf_r2_key = f"AudioBooks/{pdf_fname}"
                        pdf_local_subpath = f"AudioBooks/{pdf_fname}"

                    # Try R2 upload
                    r2_url = upload_fileobj_to_r2(pdf_file, pdf_r2_key, content_type='application/pdf')

                    if r2_url:
                        db_pdf_path = r2_url
                    else:
                        # Fallback: save locally
                        pdf_file.seek(0)
                        pdf_save_path = os.path.join(static_dir, pdf_local_subpath)
                        os.makedirs(os.path.dirname(pdf_save_path), exist_ok=True)
                        pdf_file.save(pdf_save_path)
                        db_pdf_path = f"{BASE_URL}static/{pdf_local_subpath}"

        finally:
            # Clean up temp directory
            shutil.rmtree(temp_dir, ignore_errors=True)

        # Insert Book
        # Calculate total duration for playlists
        total_duration = sum(item.get('duration', 0) for item in saved_files_info)
        
        insert_query = """
            INSERT INTO books
            (title, author, primary_category_id, audio_path, cover_image_path, posted_by_user_id, description, price, duration_seconds, pdf_path, premium, background_music_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """
        params = (title, author, numeric_cat_id, main_audio_path, db_cover_path, user_id, description, price, total_duration, db_pdf_path, int(is_premium), background_music_id)
        
        cursor = db.connection.cursor()
        cursor.execute(insert_query, params)
        book_id = cursor.fetchone()[0]
        
        # Insert Playlist Items if Playlist
        if is_playlist:
            pl_query = """
                INSERT INTO playlist_items (book_id, file_path, title, track_order, duration_seconds)
                VALUES (%s, %s, %s, %s, %s)
            """
            for item in saved_files_info:
                cursor.execute(pl_query, (book_id, item['path'], item['title'], item['order'], item.get('duration', 0)))

        # Auto-Buy
        own_query = "INSERT INTO user_books (user_id, book_id) VALUES (%s, %s)"
        cursor.execute(own_query, (user_id, book_id))
        
        db.connection.commit()
        cursor.close()
        db.disconnect()
        
        return jsonify({"message": "Book/Playlist uploaded successfully", "book_id": book_id}), 201

    except Exception as e:
        print(f"Upload Error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/my_uploads', methods=['GET'])
@jwt_required
def get_my_uploads():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"error": "User ID required"}), 400

    db = Database()
    if not db.connect():
         return jsonify({"error": "Database error"}), 500

    # Admin check - only admin can view uploads
    if not is_admin_user(user_id, db):
        db.disconnect()
        return jsonify([]), 200  # Return empty list for non-admin users

    query = """
        SELECT b.id, b.title, b.author, b.audio_path, b.cover_image_path, c.slug as category_slug,
               b.description, b.price, b.posted_by_user_id, b.pdf_path, b.premium,
               (SELECT COUNT(*) FROM playlist_items WHERE book_id = b.id) as playlist_count
        FROM books b
        LEFT JOIN categories c ON b.primary_category_id = c.id
        WHERE b.posted_by_user_id = %s
        ORDER BY b.id DESC
    """
    
    books_result = db.execute_query(query, (user_id,))
    
    books = []
    if books_result:
        for row in books_result:
             # Resolve audio URL (handles R2 refs, http, and relative paths)
             audio_path = resolve_stored_url(row['audio_path'], "AudioBooks")

             # Resolve cover URL and thumbnail (handles R2 and local)
             cover_path, cover_thumbnail_path = resolve_cover_urls(row['cover_image_path'])

             books.append({
                "id": str(row['id']),
                "title": row['title'],
                "author": row['author'],
                "audioUrl": audio_path,
                "coverUrl": cover_path,
                "coverUrlThumbnail": cover_thumbnail_path,
                "categoryId": row['category_slug'] or "",
                "description": row['description'],
                "price": float(row['price']) if row['price'] else 0.0,
                "postedByUserId": str(row['posted_by_user_id']),
                "isPlaylist": row['playlist_count'] > 0,
                "pdfUrl": resolve_stored_url(row['pdf_path'], "AudioBooks"),
                "premium": row['premium'] or 0
            })

    return jsonify(books)

@app.route('/quiz/result', methods=['POST'])
def save_quiz_result():
    data = request.get_json()
    user_id = data.get('user_id')
    book_id = data.get('book_id')
    score_percentage = data.get('score_percentage')

    if not all([user_id, book_id, score_percentage is not None]):
        return jsonify({"error": "Missing data"}), 400

    # Ensure correct types (Flutter may send book_id as string)
    try:
        book_id = int(book_id)
    except (ValueError, TypeError):
        return jsonify({"error": "Invalid book_id"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        # Get Quiz ID
        # Logic needs to handle track quizzes
        # We can either pass quiz_id directly OR (book_id + optional playlist_item_id)
        
        # Current frontend sends book_id.
        # If we add playlist_item_id to payload, we can look up specific quiz.
        
        playlist_item_id = data.get('playlist_item_id')
        
        q_query = "SELECT id FROM quizzes WHERE book_id = %s"
        params = [book_id]
        
        if playlist_item_id:
            q_query += " AND playlist_item_id = %s"
            params.append(playlist_item_id)
        else:
            q_query += " AND playlist_item_id IS NULL"
            
        q_res = db.execute_query(q_query, tuple(params))
        if not q_res:
            return jsonify({"error": "Quiz not found"}), 404
        quiz_id = q_res[0]['id']
        
        is_passed = 1 if float(score_percentage) > 50.0 else 0
        
        ins_query = """
            INSERT INTO user_quiz_results (user_id, quiz_id, score_percentage, is_passed)
            VALUES (%s, %s, %s, %s)
        """
        cursor = db.connection.cursor()
        cursor.execute(ins_query, (user_id, quiz_id, score_percentage, is_passed))
        db.connection.commit()
        cursor.close()

        new_badges = []

        # If quiz passed, check if book should now be marked as complete
        if is_passed:
            # Check if all tracks are completed
            count_query = "SELECT COUNT(*) as total FROM playlist_items WHERE book_id = %s"
            total_tracks = db.execute_query(count_query, (book_id,))[0]['total']

            completed_query = """
                SELECT COUNT(*) as completed
                FROM user_completed_tracks uct
                JOIN playlist_items pi ON uct.track_id = pi.id
                WHERE uct.user_id = %s AND pi.book_id = %s
            """
            completed_tracks = db.execute_query(completed_query, (user_id, book_id))[0]['completed']

            if completed_tracks >= total_tracks:
                # All tracks done, check all quizzes
                # 1. Book-level quiz
                book_quiz_query = """
                    SELECT q.id FROM quizzes q
                    WHERE q.book_id = %s AND q.playlist_item_id IS NULL
                """
                book_quiz = db.execute_query(book_quiz_query, (book_id,))

                book_quiz_passed = True
                if book_quiz and len(book_quiz) > 0:
                    bq_id = book_quiz[0]['id']
                    passed_query = """
                        SELECT is_passed FROM user_quiz_results
                        WHERE user_id = %s AND quiz_id = %s AND is_passed = 1
                        LIMIT 1
                    """
                    passed_res = db.execute_query(passed_query, (user_id, bq_id))
                    book_quiz_passed = bool(passed_res)

                # 2. Track-level quizzes
                track_quizzes_query = """
                    SELECT q.id FROM quizzes q
                    WHERE q.book_id = %s AND q.playlist_item_id IS NOT NULL
                """
                track_quizzes = db.execute_query(track_quizzes_query, (book_id,))

                all_track_quizzes_passed = True
                if track_quizzes and len(track_quizzes) > 0:
                    for tq in track_quizzes:
                        passed_query = """
                            SELECT is_passed FROM user_quiz_results
                            WHERE user_id = %s AND quiz_id = %s AND is_passed = 1
                            LIMIT 1
                        """
                        passed_res = db.execute_query(passed_query, (user_id, tq['id']))
                        if not passed_res:
                            all_track_quizzes_passed = False
                            break

                if book_quiz_passed and all_track_quizzes_passed:
                    print(f"User {user_id} fully completed book {book_id} after passing quiz")

                    # Mark book as read
                    update_read = "UPDATE user_books SET is_read = 1, last_accessed_at = CURRENT_TIMESTAMP WHERE user_id = %s AND book_id = %s"
                    db.execute_query(update_read, (user_id, book_id))

                    # Check badges
                    try:
                        badge_service = BadgeService(db.connection)
                        new_badges = badge_service.check_badges(user_id)
                    except Exception as b_err:
                        print(f"Badge check error: {b_err}")

        return jsonify({"message": "Result saved", "passed": is_passed, "new_badges": new_badges}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

# ===================== SUBSCRIPTION ENDPOINTS =====================

@app.route('/subscription/status', methods=['GET'])
@jwt_required
def get_subscription_status():
    """Get user's current subscription status."""
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"error": "User ID required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        query = """
            SELECT id, plan_type, status, start_date, end_date, auto_renew, created_at
            FROM subscriptions
            WHERE user_id = %s
        """
        result = db.execute_query(query, (user_id,))

        if result:
            sub = result[0]
            # Check for auto-renewal if expired
            now = datetime.datetime.utcnow()
            
            # Lazy Auto-Renewal Logic
            if sub['end_date'] and sub['end_date'] < now and sub['auto_renew']:
                # Determine duration based on plan_type
                plan = sub['plan_type']
                duration = datetime.timedelta(days=30) # default
                
                if plan == 'test_minute':
                    duration = datetime.timedelta(minutes=1)
                elif plan == 'yearly':
                    duration = datetime.timedelta(days=365)
                elif plan == 'lifetime':
                    duration = None
                
                if duration:
                    # Calculate new dates
                    # If it expired a long time ago, restart from now. 
                    # If it just expired, maybe we should add to end_date? 
                    # For simplicity and "reactivation", let's restart from NOW to give full value.
                    new_start = now
                    new_end = now + duration
                    
                    # Update DB
                    update_query = """
                        UPDATE subscriptions 
                        SET start_date = %s, end_date = %s, status = 'active' 
                        WHERE id = %s
                    """
                    cursor = db.connection.cursor()
                    cursor.execute(update_query, (new_start, new_end, sub['id']))
                    
                    # Log renewal
                    history_query = """
                        INSERT INTO subscription_history (user_id, action, plan_type, notes)
                        VALUES (%s, 'renewed', %s, 'Auto-renewal via status check')
                    """
                    cursor.execute(history_query, (int(user_id), plan))
                    db.connection.commit()
                    cursor.close()
                    
                    invalidate_user_cache(user_id)
                    
                    # Update local variable for return
                    sub['start_date'] = new_start
                    sub['end_date'] = new_end
                    sub['status'] = 'active'
                    is_active = True
            
            # Re-check active status after potential renewal
            is_active = sub['status'] == 'active'
            if is_active and sub['end_date']:
                 is_active = sub['end_date'] > now

            # Convert naive datetime to UTC timestamp properly
            # MySQL stores UTC but returns naive datetime, so we need to treat it as UTC
            def to_utc_timestamp(dt):
                if dt is None:
                    return None
                # Treat the naive datetime as UTC
                return int(dt.replace(tzinfo=datetime.timezone.utc).timestamp())

            return jsonify({
                "id": sub['id'],
                "user_id": int(user_id),
                "plan_type": sub['plan_type'],
                "status": "active" if is_active else "expired",
                "start_date": to_utc_timestamp(sub['start_date']),
                "end_date": to_utc_timestamp(sub['end_date']),
                "auto_renew": bool(sub['auto_renew']),
                "is_active": is_active
            }), 200
        else:
            # No subscription found
            return jsonify({
                "user_id": int(user_id),
                "status": "none",
                "is_active": False
            }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/subscription/subscribe', methods=['POST'])
@jwt_required
def subscribe():
    """Create or renew a subscription (Test Mode - no real payment)."""
    data = request.get_json()
    user_id = data.get('user_id')
    plan_type = data.get('plan_type', 'monthly')  # test_minute, monthly, yearly, lifetime

    if not user_id:
        return jsonify({"error": "User ID required"}), 400

    if plan_type not in ['test_minute', 'monthly', 'yearly', 'lifetime']:
        return jsonify({"error": "Invalid plan type"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Calculate end_date based on plan
        now = datetime.datetime.utcnow()
        if plan_type == 'test_minute':
            end_date = now + datetime.timedelta(minutes=1)
        elif plan_type == 'monthly':
            end_date = now + datetime.timedelta(days=30)
        elif plan_type == 'yearly':
            end_date = now + datetime.timedelta(days=365)
        else:  # lifetime
            end_date = None

        # Check if subscription exists
        check_query = "SELECT id, status FROM subscriptions WHERE user_id = %s"
        existing = db.execute_query(check_query, (user_id,))

        cursor = db.connection.cursor()

        if existing:
            # Update existing subscription
            update_query = """
                UPDATE subscriptions
                SET plan_type = %s, status = 'active', start_date = %s, end_date = %s, auto_renew = 1
                WHERE user_id = %s
            """
            cursor.execute(update_query, (plan_type, now, end_date, user_id))
            action = 'renewed'
        else:
            # Create new subscription
            insert_query = """
                INSERT INTO subscriptions (user_id, plan_type, status, start_date, end_date, auto_renew)
                VALUES (%s, %s, 'active', %s, %s, 1)
            """
            cursor.execute(insert_query, (user_id, plan_type, now, end_date))
            action = 'subscribed'

        # Log to history
        history_query = """
            INSERT INTO subscription_history (user_id, action, plan_type, notes)
            VALUES (%s, %s, %s, %s)
        """
        cursor.execute(history_query, (user_id, action, plan_type, f"Test mode subscription - {plan_type}"))

        db.connection.commit()
        cursor.close()

        # end_date is UTC naive datetime, convert properly
        end_date_ts = int(end_date.replace(tzinfo=datetime.timezone.utc).timestamp()) if end_date else None

        invalidate_user_cache(user_id)
        return jsonify({
            "message": f"Subscription {action} successfully",
            "plan_type": plan_type,
            "end_date": end_date_ts,
            "status": "active"
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/subscription/cancel', methods=['POST'])
@jwt_required
def cancel_subscription():
    """Cancel subscription (keeps active until end_date)."""
    data = request.get_json()
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"error": "User ID required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Update subscription to not auto-renew (keep status active until actual expiry)
        update_query = """
            UPDATE subscriptions
            SET auto_renew = 0
            WHERE user_id = %s
        """
        db.execute_query(update_query, (user_id,))

        # Log to history
        cursor = db.connection.cursor()
        history_query = """
            INSERT INTO subscription_history (user_id, action, notes)
            VALUES (%s, 'cancelled', 'User cancelled subscription')
        """
        cursor.execute(history_query, (user_id,))
        db.connection.commit()
        cursor.close()

        invalidate_user_cache(user_id)
        return jsonify({"message": "Subscription cancelled"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/subscription/admin/set', methods=['POST'])
@jwt_required
def admin_set_subscription():
    """Admin endpoint to manually set subscription (for testing).

    Requires JWT authentication AND the authenticated user must be the admin.
    """
    data = request.get_json()
    target_email = data.get('email')
    plan_type = data.get('plan_type', 'monthly')
    duration_days = data.get('duration_days', 30)
    action = data.get('action', 'activate')  # activate or deactivate

    # Get the authenticated user's ID from JWT (set by jwt_required decorator)
    auth_user_id = getattr(request, 'user_id', None)

    if not auth_user_id:
        return jsonify({"error": "Authentication required"}), 401

    # Verify the authenticated user is actually the admin
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    if not is_admin_user(auth_user_id, db):
        db.disconnect()
        return jsonify({"error": "Admin access required"}), 403

    if not target_email:
        db.disconnect()
        return jsonify({"error": "Target email required"}), 400

    try:
        # Get target user ID
        user_query = "SELECT id FROM users WHERE email = %s"
        user_result = db.execute_query(user_query, (target_email,))

        if not user_result:
            return jsonify({"error": "User not found"}), 404

        user_id = user_result[0]['id']
        cursor = db.connection.cursor()

        if action == 'deactivate':
            # Deactivate subscription
            update_query = "UPDATE subscriptions SET status = 'expired' WHERE user_id = %s"
            cursor.execute(update_query, (user_id,))
            db.connection.commit()
            cursor.close()
            invalidate_user_cache(user_id)
            return jsonify({"message": f"Subscription deactivated for {target_email}"}), 200

        # Activate subscription
        now = datetime.datetime.utcnow()
        end_date = now + datetime.timedelta(days=duration_days) if plan_type != 'lifetime' else None

        # Upsert subscription
        upsert_query = """
            INSERT INTO subscriptions (user_id, plan_type, status, start_date, end_date, auto_renew)
            VALUES (%s, %s, 'active', %s, %s, 1)
            ON CONFLICT (user_id) DO UPDATE SET
                plan_type = EXCLUDED.plan_type,
                status = 'active',
                start_date = EXCLUDED.start_date,
                end_date = EXCLUDED.end_date,
                auto_renew = 1
        """
        cursor.execute(upsert_query, (user_id, plan_type, now, end_date))
        db.connection.commit()
        cursor.close()

        # end_date is UTC naive datetime, convert properly
        end_date_ts = int(end_date.replace(tzinfo=datetime.timezone.utc).timestamp()) if end_date else "lifetime"

        invalidate_user_cache(user_id)
        return jsonify({
            "message": f"Subscription activated for {target_email}",
            "plan_type": plan_type,
            "end_date": end_date_ts
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

# Support/Contact Email endpoint
@app.route('/send-support-email', methods=['POST'])
@jwt_required
def send_support_email_endpoint():
    """Send support/contact message via email"""
    user_id = getattr(request, 'user_id', None)
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    try:
        data = request.get_json()
        message = data.get('message', '').strip()

        if not message:
            return jsonify({"error": "Message cannot be empty"}), 400

        if len(message) > 5000:
            return jsonify({"error": "Message too long (max 5000 characters)"}), 400

        # Get user info
        user_query = "SELECT name, email FROM users WHERE id = %s"
        user_result = db.execute_query(user_query, (user_id,))

        if not user_result:
            return jsonify({"error": "User not found"}), 404

        user_name = user_result[0]['name'] or 'Unknown User'
        user_email = user_result[0]['email']

        # Check if user is admin
        is_admin = is_admin_user(user_id, db)

        # Send email
        from email_service import send_support_email
        success, error = send_support_email(
            user_name=user_name,
            user_email=user_email,
            user_id=user_id,
            message=message,
            is_admin=is_admin
        )

        if success:
            return jsonify({
                "message": "Email sent successfully",
                "success": True
            }), 200
        else:
            print(f"Email send failed: {error}")
            return jsonify({
                "error": "Failed to send email",
                "details": error,
                "success": False
            }), 500

    except Exception as e:
        print(f"Error in send_support_email: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# ==================== BOOK RATINGS ====================

@app.route('/books/<int:book_id>/rate', methods=['POST'])
@jwt_required
def rate_book(book_id):
    """Submit or update a rating for a book (1-5 stars). Subscribers only."""
    data = request.get_json()
    user_id = data.get('user_id')
    stars = data.get('stars')
    
    if not user_id or stars is None:
        return jsonify({"error": "user_id and stars are required"}), 400
    
    if not isinstance(stars, int) or stars < 1 or stars > 5:
        return jsonify({"error": "stars must be an integer from 1 to 5"}), 400
    
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # Check if user is a subscriber
        if not is_subscriber(user_id, db):
            return jsonify({"error": "Only subscribers can rate books"}), 403
        
        # Create table if not exists (PostgreSQL syntax)
        create_table_query = """
            CREATE TABLE IF NOT EXISTS book_ratings (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL,
                user_id INT NOT NULL,
                stars INT NOT NULL CHECK (stars >= 1 AND stars <= 5),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT unique_user_book UNIQUE (user_id, book_id),
                CONSTRAINT fk_book_ratings_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
                CONSTRAINT fk_book_ratings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """
        cursor = db.connection.cursor()
        cursor.execute(create_table_query)
        db.connection.commit()
        
        # Insert or update rating
        upsert_query = """
            INSERT INTO book_ratings (book_id, user_id, stars)
            VALUES (%s, %s, %s)
            ON CONFLICT (book_id, user_id) DO UPDATE SET 
                stars = EXCLUDED.stars, 
                updated_at = CURRENT_TIMESTAMP
        """
        cursor.execute(upsert_query, (book_id, user_id, stars))
        db.connection.commit()
        cursor.close()
        
        # Return updated rating stats
        stats_query = """
            SELECT AVG(stars) as average_rating, COUNT(*) as rating_count
            FROM book_ratings WHERE book_id = %s
        """
        stats = db.execute_query(stats_query, (book_id,))
        avg = round(float(stats[0]['average_rating']), 1) if stats and stats[0]['average_rating'] else 0
        count = stats[0]['rating_count'] if stats else 0
        
        return jsonify({
            "message": "Rating submitted",
            "averageRating": avg,
            "ratingCount": count
        }), 200
        
    except Exception as e:
        print(f"Rating error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


@app.route('/books/<int:book_id>/rating', methods=['GET'])
def get_book_rating(book_id):
    """Get average rating and count for a book."""
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        query = """
            SELECT AVG(stars) as average_rating, COUNT(*) as rating_count
            FROM book_ratings WHERE book_id = %s
        """
        result = db.execute_query(query, (book_id,))
        
        if result and result[0]['average_rating']:
            return jsonify({
                "averageRating": round(float(result[0]['average_rating']), 1),
                "ratingCount": result[0]['rating_count']
            }), 200
        else:
            return jsonify({
                "averageRating": 0,
                "ratingCount": 0
            }), 200
            
    except Exception as e:
        # Table might not exist yet - return empty
        return jsonify({
            "averageRating": 0,
            "ratingCount": 0
        }), 200
    finally:
        db.disconnect()


@app.route('/books/<int:book_id>/user-rating/<int:user_id>', methods=['GET'])
@jwt_required
def get_user_book_rating(book_id, user_id):
    """Get a specific user's rating for a book."""
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        query = "SELECT stars FROM book_ratings WHERE book_id = %s AND user_id = %s"
        result = db.execute_query(query, (book_id, user_id))
        
        if result:
            return jsonify({"stars": result[0]['stars']}), 200
        else:
            return jsonify({"stars": None}), 200
            
    except Exception as e:
        return jsonify({"stars": None}), 200
    finally:
        db.disconnect()


# ===================== COMBINED PROFILE-INIT ENDPOINT =====================
@app.route('/profile-init/<int:user_id>', methods=['GET'])
@jwt_required
def profile_init(user_id):
    """
    Combined endpoint for the profile screen. Returns in ONE call:
    - user profile, listen history, user stats, badges, subscription status
    Replaces 5 separate API calls with 1.
    """
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # 1. User profile
        user_data = None
        auth_header = request.headers.get('Authorization')
        if auth_header:
            access_token = auth_header.split()[1]
            payload = pyjwt.decode(access_token, options={"verify_signature": False})
            token_user_id = payload.get('user_id')
            users = db.execute_query(
                "SELECT id, name, email, profile_picture_url, is_verified FROM users WHERE id = %s",
                (token_user_id,)
            )
            if users:
                user = users[0]
                aes_key = get_or_create_user_aes_key(user['id'], db)
                user_data = {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "profile_picture_url": resolve_stored_url(user['profile_picture_url'], "profilePictures"),
                    "aes_key": aes_key
                }

        # 2. Listen history with batched progress queries
        history = []
        books_query = """
            SELECT DISTINCT b.id, b.title, b.author, b.audio_path, b.cover_image_path,
                   c.slug as category_slug, b.duration_seconds, ub.last_accessed_at,
                   b.premium,
                   br_stats.avg_rating as average_rating,
                   COALESCE(br_stats.rating_cnt, 0) as rating_count,
                   COALESCE(pi_count.cnt, 0) as playlist_count
            FROM user_books ub
            JOIN books b ON ub.book_id = b.id
            LEFT JOIN categories c ON b.primary_category_id = c.id
            LEFT JOIN (SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id) pi_count ON pi_count.book_id = b.id
            LEFT JOIN (SELECT book_id, AVG(stars) as avg_rating, COUNT(*) as rating_cnt FROM book_ratings GROUP BY book_id) br_stats ON br_stats.book_id = b.id
            WHERE ub.user_id = %s AND ub.last_played_position_seconds > 0
            ORDER BY ub.last_accessed_at DESC
        """
        books_result = db.execute_query(books_query, (user_id,))

        # Batch fetch all progress data once for history + stats
        all_user_book_ids = []
        if books_result:
            all_user_book_ids = [b['id'] for b in books_result]

        # Also get all user books for stats
        ub_query = """
            SELECT b.id, b.duration_seconds,
                   COALESCE(pi_count.cnt, 0) as playlist_count
            FROM user_books ub
            JOIN books b ON ub.book_id = b.id
            LEFT JOIN (SELECT book_id, COUNT(*) as cnt FROM playlist_items GROUP BY book_id) pi_count ON pi_count.book_id = b.id
            WHERE ub.user_id = %s
        """
        ub_result = db.execute_query(ub_query, (user_id,))
        stat_book_ids = [b['id'] for b in ub_result] if ub_result else []

        # Combine all book IDs for a single batch fetch
        combined_ids = list(set(all_user_book_ids + stat_book_ids))

        tracks_by_book = {}
        single_by_book = {}
        if combined_ids:
            ph = ','.join(['%s'] * len(combined_ids))
            tracks_q = f"""
                SELECT pi.book_id, pi.id as playlist_item_id, pi.duration_seconds,
                       COALESCE(MAX(ph.played_seconds), 0) as last_position,
                       CASE WHEN uct.id IS NOT NULL THEN 1 ELSE 0 END as is_completed
                FROM playlist_items pi
                LEFT JOIN playback_history ph ON ph.playlist_item_id = pi.id AND ph.user_id = %s
                LEFT JOIN user_completed_tracks uct ON uct.track_id = pi.id AND uct.user_id = %s
                WHERE pi.book_id IN ({ph})
                GROUP BY pi.id, pi.book_id, pi.duration_seconds, uct.id
            """
            tracks_result = db.execute_query(tracks_q, (user_id, user_id, *combined_ids))
            if tracks_result:
                for t in tracks_result:
                    bid = t['book_id']
                    if bid not in tracks_by_book:
                        tracks_by_book[bid] = []
                    tracks_by_book[bid].append(t)

            single_q = f"""
                SELECT book_id, COALESCE(MAX(played_seconds), 0) as last_position
                FROM playback_history WHERE user_id = %s AND book_id IN ({ph})
                GROUP BY book_id
            """
            single_result = db.execute_query(single_q, (user_id, *combined_ids))
            if single_result:
                for r in single_result:
                    single_by_book[r['book_id']] = r['last_position'] or 0

        # Build history response
        if books_result:
            for book in books_result:
                book_id = book['id']
                is_playlist = book['playlist_count'] > 0
                total_listened = 0
                if is_playlist:
                    for track in tracks_by_book.get(book_id, []):
                        td = track['duration_seconds'] or 0
                        if track['is_completed'] and td > 0:
                            total_listened += td
                        else:
                            lp = track['last_position'] or 0
                            total_listened += min(lp, td) if td > 0 else lp
                else:
                    total_listened = single_by_book.get(book_id, 0)

                cover_path, cover_thumb = resolve_cover_urls(book['cover_image_path'])
                audio_path = resolve_stored_url(book['audio_path'], "AudioBooks")
                total_duration = book['duration_seconds'] or 0
                pct = (total_listened / total_duration * 100) if total_duration > 0 else 0

                history.append({
                    "id": str(book_id), "title": book['title'], "author": book['author'],
                    "audioUrl": audio_path, "coverUrl": cover_path, "coverUrlThumbnail": cover_thumb,
                    "categoryId": book['category_slug'] or "", "lastPosition": int(total_listened),
                    "duration": total_duration, "percentage": round(pct, 2),
                    "lastAccessed": str(book['last_accessed_at']),
                    "averageRating": float(book['average_rating'] or 0),
                    "ratingCount": int(book['rating_count'] or 0),
                    "premium": bool(book['premium'])
                })

        # 3. Stats (reuse batched data)
        total_seconds = 0
        completed_count = 0
        if ub_result:
            for book in ub_result:
                bid = book['id']
                is_playlist = book['playlist_count'] > 0
                total_duration = book['duration_seconds'] or 0
                if is_playlist:
                    book_listened = 0
                    for track in tracks_by_book.get(bid, []):
                        td = track['duration_seconds'] or 0
                        if track['is_completed'] and td > 0:
                            book_listened += td
                        else:
                            lp = track['last_position'] or 0
                            book_listened += min(lp, td) if td > 0 else lp
                    total_seconds += book_listened
                    if total_duration > 0 and book_listened >= total_duration:
                        completed_count += 1
                else:
                    listened = single_by_book.get(bid, 0)
                    total_seconds += listened
                    if total_duration > 0 and listened >= (total_duration * 0.95):
                        completed_count += 1
        stats = {"total_listening_time_seconds": total_seconds, "books_completed": completed_count}

        # 4. Badges
        badge_service = BadgeService(db.connection)
        badges = badge_service.get_all_badges_with_progress(user_id)

        # 5. Subscription
        sub_data = {"user_id": user_id, "status": "none", "is_active": False}
        sub_result = db.execute_query(
            "SELECT id, plan_type, status, start_date, end_date, auto_renew FROM subscriptions WHERE user_id = %s",
            (user_id,)
        )
        if sub_result:
            sub = sub_result[0]
            now = datetime.datetime.utcnow()
            if sub['end_date'] and sub['end_date'] < now and sub['auto_renew']:
                plan = sub['plan_type']
                duration = datetime.timedelta(days=30)
                if plan == 'test_minute': duration = datetime.timedelta(minutes=1)
                elif plan == 'yearly': duration = datetime.timedelta(days=365)
                elif plan == 'lifetime': duration = None
                if duration:
                    new_start, new_end = now, now + duration
                    cursor = db.connection.cursor()
                    cursor.execute("UPDATE subscriptions SET start_date=%s, end_date=%s, status='active' WHERE id=%s", (new_start, new_end, sub['id']))
                    cursor.execute("INSERT INTO subscription_history (user_id,action,plan_type,notes) VALUES (%s,'renewed',%s,'Auto-renewal via profile-init')", (user_id, plan))
                    db.connection.commit()
                    cursor.close()
                    sub['start_date'], sub['end_date'], sub['status'] = new_start, new_end, 'active'
            is_active = sub['status'] == 'active'
            if is_active and sub['end_date']:
                is_active = sub['end_date'] > now
            def to_ts(dt):
                return int(dt.replace(tzinfo=datetime.timezone.utc).timestamp()) if dt else None
            sub_data = {
                "id": sub['id'], "user_id": user_id, "plan_type": sub['plan_type'],
                "status": "active" if is_active else "expired",
                "start_date": to_ts(sub['start_date']), "end_date": to_ts(sub['end_date']),
                "auto_renew": bool(sub['auto_renew']), "is_active": is_active
            }

        # 6. Chart Stats (heatmap, genres, weekly, mastery) — merged from /user/stats
        chart_stats = {}

        # 6a. Listening Heatmap (Last 365 days)
        try:
            heatmap_query = """
                SELECT DATE(start_time) as day, SUM(played_seconds) as total_seconds
                FROM playback_history
                WHERE user_id = %s
                  AND start_time > NOW() - INTERVAL '365 days'
                GROUP BY day
                ORDER BY day
            """
            heatmap_rows = db.execute_query(heatmap_query, (user_id,))
            if heatmap_rows:
                chart_stats['heatmap'] = {
                    str(row['day']): round(row['total_seconds'] / 60)
                    for row in heatmap_rows
                }
            else:
                chart_stats['heatmap'] = {}
        except Exception as e:
            print(f"Error fetching heatmap in profile-init: {e}")
            chart_stats['heatmap'] = {}

        # 6b. Genre Distribution
        try:
            genre_query = """
                SELECT c.slug, c.name, COUNT(DISTINCT ub.book_id) as count
                FROM user_books ub
                JOIN book_categories bc ON ub.book_id = bc.book_id
                JOIN categories c ON bc.category_id = c.id
                WHERE ub.user_id = %s
                GROUP BY c.slug, c.name
                ORDER BY count DESC
                LIMIT 8
            """
            genre_rows = db.execute_query(genre_query, (user_id,))
            if genre_rows:
                chart_stats['genres'] = [
                    {"slug": row['slug'], "name": row['name'], "count": row['count']}
                    for row in genre_rows
                ]
            else:
                chart_stats['genres'] = []
        except Exception as e:
            print(f"Error fetching genres in profile-init: {e}")
            chart_stats['genres'] = []

        # 6c. Weekly Activity (Last 7 days)
        try:
            weekly_query = """
                SELECT DATE(start_time) as day, SUM(played_seconds) as total_seconds, EXTRACT(DOW FROM start_time) as dow
                FROM playback_history
                WHERE user_id = %s
                  AND start_time > NOW() - INTERVAL '7 days'
                GROUP BY day, dow
                ORDER BY day
            """
            weekly_rows = db.execute_query(weekly_query, (user_id,))
            if weekly_rows:
                chart_stats['weekly'] = [
                    {
                        "date": str(row['day']),
                        "minutes": round(row['total_seconds'] / 60),
                        "dow": int(row['dow'])
                    }
                    for row in weekly_rows
                ]
            else:
                chart_stats['weekly'] = []
        except Exception as e:
            print(f"Error fetching weekly stats in profile-init: {e}")
            chart_stats['weekly'] = []

        # 6d. Mastery
        try:
            books_read_query = "SELECT COUNT(*) as count FROM user_books WHERE user_id = %s AND is_read = 1"
            books_read_res = db.execute_query(books_read_query, (user_id,))
            books_read = books_read_res[0]['count'] if books_read_res else 0

            quizzes_passed_query = "SELECT COUNT(DISTINCT quiz_id) as count FROM user_quiz_results WHERE user_id = %s AND is_passed = 1"
            quizzes_passed_res = db.execute_query(quizzes_passed_query, (user_id,))
            quizzes_passed = quizzes_passed_res[0]['count'] if quizzes_passed_res else 0

            total_books_query = "SELECT COUNT(*) as count FROM books"
            total_books_res = db.execute_query(total_books_query)
            total_books = total_books_res[0]['count'] if total_books_res else 0

            chart_stats['mastery'] = {
                "books_read": books_read,
                "books_total": total_books,
                "quizzes_passed": quizzes_passed
            }
        except Exception as e:
            print(f"Error fetching mastery in profile-init: {e}")
            chart_stats['mastery'] = {"books_read": 0, "books_total": 0, "quizzes_passed": 0}

        return jsonify({
            "user": user_data, "listenHistory": history, "stats": stats,
            "badges": badges, "subscription": sub_data,
            "chartStats": chart_stats,
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# ===================== COMBINED APP-INIT ENDPOINT =====================
@app.route('/app-init', methods=['GET'])
def app_init():
    """
    Combined endpoint for app startup. Returns categories + background music in ONE call.
    No auth required. Replaces 2 separate API calls.
    """
    # Check cache
    cached_data = cache.get("app_init")
    if cached_data:
        response = jsonify(cached_data)
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 min CDN cache
        return response, 200

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    try:
        cat_result = db.execute_query("SELECT id, name, slug, parent_id FROM categories ORDER BY id ASC")
        categories = build_category_tree(cat_result) if cat_result else []

        bg_result = db.execute_query("SELECT id, title, file_path, is_default FROM background_music ORDER BY title ASC")
        music_list = []
        if bg_result:
            for row in bg_result:
                url = resolve_stored_url(row['file_path'], "BackgroundMusic")
                music_list.append({"id": row['id'], "title": row['title'], "url": url, "isDefault": bool(row['is_default'])})

        response_data = {"categories": categories, "backgroundMusic": music_list}
        cache.set("app_init", response_data, 300)
        response = jsonify(response_data)
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 min CDN cache
        return response, 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# Register new encryption endpoints (v2)
# from api_encryption_endpoints import register_encryption_endpoints
# register_encryption_endpoints(app)

if __name__ == '__main__':
    # Run on 0.0.0.0 to be accessible, port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)

# WSGI entry point
application = app
@app.route('/debug/migrate_bg_music', methods=['GET'])
def debug_migrate_bg_music():
    """Temporary route to migrate DB for background music."""
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # 1. Create background_music table
        create_table_query = """
            CREATE TABLE IF NOT EXISTS background_music (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                file_path VARCHAR(255) NOT NULL,
                is_default BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        db.execute_query(create_table_query)
        
        # 2. Add background_music_id to books
        try:
             alter_query = "ALTER TABLE books ADD COLUMN background_music_id INT DEFAULT NULL"
             db.execute_query(alter_query)
        except Exception as e:
             pass # Column likely exists

        return jsonify({"message": "Migration executed"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/upload-bg-music', methods=['POST'])
@jwt_required
def upload_bg_music():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    title = request.form.get('title')
    is_default = request.form.get('is_default') == 'true'
    
    if not file or not title:
        return jsonify({"error": "File and title are required"}), 400
        
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        # Upload file (simulating book upload logic roughly)
        filename = secure_filename(file.filename)
        timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        unique_filename = f"{timestamp}_{filename}"
        
        # Upload to R2 (BackgroundMusic folder)
        r2_key = f"BackgroundMusic/{unique_filename}"
        file_url = upload_fileobj_to_r2(file, r2_key)
        
        if not file_url:
             # Fallback to local? Assuming R2 logic
             # If upload_fileobj_to_r2 returns None, usually failed.
             pass
             
        # Insert into DB (Store with r2:// prefix)
        db_path = f"r2://{r2_key}"
        insert_query = "INSERT INTO background_music (title, file_path, is_default) VALUES (%s, %s, %s)"
        result = db.execute_query(insert_query, (title, db_path, is_default)) 
        
        if result is None:
             return jsonify({"error": "Database insert failed (check server logs)"}), 500

        return jsonify({"message": "Background music uploaded successfully"}), 200
    except Exception as e:
        print(f"Error uploading bg music: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/background-music', methods=['GET'])
def get_bg_music_list():
    # Check cache first
    cached_data = cache.get("bg_music_list")
    if cached_data:
        response = jsonify(cached_data)
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 min CDN cache
        return response, 200

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
        
    try:
        query = "SELECT id, title, file_path, is_default FROM background_music ORDER BY title ASC"
        results = db.execute_query(query)
        
        music_list = []
        if results:
            for row in results:
                # Resolve URL
                url = resolve_stored_url(row['file_path'], "BackgroundMusic")
                music_list.append({
                    "id": row['id'],
                    "title": row['title'],
                    "url": url,
                    "isDefault": bool(row['is_default'])
                })
        
        cache.set("bg_music_list", music_list, 300)  # 5 min server cache
        response = jsonify(music_list)
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 min CDN cache
        return response, 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# ==================== EMAIL SETTINGS & NOTIFICATIONS ====================

@app.route('/debug/migrate_email_settings', methods=['GET'])
def debug_migrate_email_settings():
    """Temporary route to add email settings columns to users table."""
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # Add columns if they don't exist
        columns = [
            ("email_notifications_enabled", "SMALLINT DEFAULT 0"), # 0=False, 1=True
            ("email_notification_time", "VARCHAR(10) DEFAULT '09:00'"),
            ("email_content_new_releases", "SMALLINT DEFAULT 0"),
            ("email_content_top_picks", "SMALLINT DEFAULT 0")
        ]
        
        cursor = db.connection.cursor()
        for col_name, col_def in columns:
            try:
                alter_query = f"ALTER TABLE users ADD COLUMN {col_name} {col_def}"
                cursor.execute(alter_query)
                db.connection.commit()
            except Exception as e:
                db.connection.rollback()
                # Store error but continue (column likely exists)
                print(f"Column {col_name} might already exist: {e}")
                
        cursor.close()
        return jsonify({"message": "Email settings migration executed"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/user/email-settings', methods=['GET', 'POST'])
@jwt_required
def user_email_settings():
    """Get or Update user email notification settings."""
    user_id = getattr(request, 'user_id', None)
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        if request.method == 'GET':
            query = """
                SELECT email_notifications_enabled, email_notification_time,
                       email_content_new_releases, email_content_top_picks
                FROM users WHERE id = %s
            """
            result = db.execute_query(query, (user_id,))
            
            if result:
                row = result[0]
                return jsonify({
                    "enabled": bool(row['email_notifications_enabled']),
                    "time": row['email_notification_time'] or "09:00",
                    "newReleases": bool(row['email_content_new_releases']),
                    "topPicks": bool(row['email_content_top_picks'])
                }), 200
            else:
                return jsonify({"error": "User not found"}), 404

        elif request.method == 'POST':
            data = request.get_json()
            enabled = 1 if data.get('enabled', False) else 0
            time_val = data.get('time', '09:00')
            new_releases = 1 if data.get('newReleases', False) else 0
            top_picks = 1 if data.get('topPicks', False) else 0
            
            update_query = """
                UPDATE users SET
                    email_notifications_enabled = %s,
                    email_notification_time = %s,
                    email_content_new_releases = %s,
                    email_content_top_picks = %s
                WHERE id = %s
            """
            cursor = db.connection.cursor()
            cursor.execute(update_query, (enabled, time_val, new_releases, top_picks, user_id))
            db.connection.commit()
            cursor.close()
            
            return jsonify({"message": "Settings saved successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()

@app.route('/admin/trigger-daily-emails', methods=['POST'])
@jwt_required
def trigger_daily_emails():
    """
    Simulate triggering daily emails.
    In production, this would be called by a cron job or scheduler.
    This endpoint iterates users who have notifications enabled and 'scheduled' for now (simulated).
    """
    user_id = getattr(request, 'user_id', None)
    
    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        if not is_admin_user(user_id, db):
             return jsonify({"error": "Admin access required"}), 403

        # Select users with notifications enabled
        query = """
            SELECT id, email, name, email_notification_time, 
                   email_content_new_releases, email_content_top_picks
            FROM users 
            WHERE email_notifications_enabled = 1
        """
        users = db.execute_query(query)
        
        sent_count = 0
        if users:
            # Mock sending process
            for user in users:
                # In a real scenario, check time vs current time
                # For demo/trigger, we just "send" to everyone enabled
                print(f"Sending daily email to {user['email']} (Time: {user['email_notification_time']}) "
                      f"Content: NewReleases={user['email_content_new_releases']}, TopPicks={user['email_content_top_picks']}")
                
                # Here we would call send_email(...)
                sent_count += 1
                
        return jsonify({
            "message": f"Triggered daily emails process. Sent (simulated) to {sent_count} users.",
            "sent_count": sent_count
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


@app.route('/user/stats', methods=['GET'])
@jwt_required
def user_stats():
    """
    Returns aggregated statistics for the user profile:
    1. Listening Heatmap (last 365 days)
    2. Genre Distribution
    3. Weekly Activity (last 7 days)
    4. Mastery (Books Read / Quizzes Passed)
    """
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500

    try:
        stats = {}
        
        # 1. Listening Heatmap (Last 365 days)
        try:
            heatmap_query = """
                SELECT DATE(start_time) as day, SUM(played_seconds) as total_seconds
                FROM playback_history
                WHERE user_id = %s 
                  AND start_time > NOW() - INTERVAL '365 days'
                GROUP BY day
                ORDER BY day
            """
            heatmap_rows = db.execute_query(heatmap_query, (user_id,))
            if heatmap_rows:
                stats['heatmap'] = {
                    str(row['day']): round(row['total_seconds'] / 60) 
                    for row in heatmap_rows
                }
            else:
                 stats['heatmap'] = {}
        except Exception as e:
            print(f"Error fetching heatmap: {e}")
            stats['heatmap'] = {}

        # 2. Genre Distribution
        try:
            genre_query = """
                SELECT c.slug, c.name, COUNT(DISTINCT ub.book_id) as count
                FROM user_books ub
                JOIN book_categories bc ON ub.book_id = bc.book_id
                JOIN categories c ON bc.category_id = c.id
                WHERE ub.user_id = %s
                GROUP BY c.slug, c.name
                ORDER BY count DESC
                LIMIT 8
            """
            genre_rows = db.execute_query(genre_query, (user_id,))
            if genre_rows:
                stats['genres'] = [
                    {"slug": row['slug'], "name": row['name'], "count": row['count']}
                    for row in genre_rows
                ]
            else:
                stats['genres'] = []
        except Exception as e:
            print(f"Error fetching genres: {e}")
            stats['genres'] = []

        # 3. Weekly Activity (Last 7 days)
        try:
            weekly_query = """
                SELECT DATE(start_time) as day, SUM(played_seconds) as total_seconds, EXTRACT(DOW FROM start_time) as dow
                FROM playback_history
                WHERE user_id = %s
                  AND start_time > NOW() - INTERVAL '7 days'
                GROUP BY day, dow
                ORDER BY day
            """
            weekly_rows = db.execute_query(weekly_query, (user_id,))
            if weekly_rows:
                stats['weekly'] = [
                    {
                        "date": str(row['day']), 
                        "minutes": round(row['total_seconds'] / 60),
                        "dow": int(row['dow']) 
                    }
                    for row in weekly_rows
                ]
            else:
                stats['weekly'] = []
        except Exception as e:
            print(f"Error fetching weekly stats: {e}")
            stats['weekly'] = []

        # 4. Mastery
        try:
            books_read_query = "SELECT COUNT(*) as count FROM user_books WHERE user_id = %s AND is_read = 1"
            books_read_res = db.execute_query(books_read_query, (user_id,))
            books_read = books_read_res[0]['count'] if books_read_res else 0
            
            quizzes_passed_query = "SELECT COUNT(DISTINCT quiz_id) as count FROM user_quiz_results WHERE user_id = %s AND is_passed = 1"
            quizzes_passed_res = db.execute_query(quizzes_passed_query, (user_id,))
            quizzes_passed = quizzes_passed_res[0]['count'] if quizzes_passed_res else 0
            
            total_books_query = "SELECT COUNT(*) as count FROM books"
            total_books_res = db.execute_query(total_books_query)
            total_books = total_books_res[0]['count'] if total_books_res else 0

            stats['mastery'] = {
                "books_read": books_read,
                "books_total": total_books,
                "quizzes_passed": quizzes_passed
            }
        except Exception as e:
            print(f"Error fetching mastery stats: {e}")
            stats['mastery'] = {"books_read": 0, "books_total": 0, "quizzes_passed": 0}

        return jsonify(stats)

    except Exception as e:
        print(f"Error serving user stats: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()


# ─── Share Chapter with Friend ───────────────────────────────────────────────

@app.route('/share-chapter', methods=['POST'])
@jwt_required
def share_chapter():
    """Create a shareable link for a playlist item and email it to a friend."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing JSON body"}), 400

    playlist_item_id = data.get('playlist_item_id')
    book_id = data.get('book_id')
    friend_email = data.get('friend_email', '').strip()
    message = data.get('message', '').strip()
    user_id = data.get('user_id')

    if not playlist_item_id or not book_id or not friend_email:
        return jsonify({"error": "playlist_item_id, book_id, and friend_email are required"}), 400

    db = Database()
    if not db.connect():
        return jsonify({"error": "Database connection failed"}), 500
    try:
        # Ensure shared_chapters table exists
        db.execute_query("""
            CREATE TABLE IF NOT EXISTS shared_chapters (
                id SERIAL PRIMARY KEY,
                token VARCHAR(64) UNIQUE NOT NULL,
                sharer_user_id INT NOT NULL,
                playlist_item_id INT NOT NULL,
                book_id INT NOT NULL,
                friend_email VARCHAR(255) NOT NULL,
                message TEXT,
                created_at TIMESTAMP DEFAULT NOW(),
                expires_at TIMESTAMP NOT NULL,
                listen_count INT DEFAULT 0
            )
        """)

        # Generate token
        token = secrets.token_urlsafe(32)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=7)

        # Insert share record
        insert_query = """
            INSERT INTO shared_chapters (token, sharer_user_id, playlist_item_id, book_id, friend_email, message, expires_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        db.execute_query(insert_query, (token, user_id, playlist_item_id, book_id, friend_email, message, expires_at))

        # Fetch track + book info for email
        track_info = db.execute_query(
            "SELECT title FROM playlist_items WHERE id = %s", (playlist_item_id,)
        )
        book_info = db.execute_query(
            "SELECT title, author FROM books WHERE id = %s", (book_id,)
        )
        track_title = track_info[0]['title'] if track_info else 'a chapter'
        book_title = book_info[0]['title'] if book_info else 'an audiobook'
        book_author = book_info[0]['author'] if book_info else ''

        # Fetch sharer name
        sharer_info = db.execute_query(
            "SELECT name FROM users WHERE id = %s", (user_id,)
        )
        sharer_name = sharer_info[0]['name'] if sharer_info else 'A friend'

        # Build share URL
        share_url = f"{BASE_URL}shared/{token}"

        if friend_email == 'native_share':
             return jsonify({"message": "Link generated successfully", "token": token, "share_url": share_url}), 200

        # Build email HTML
        import html
        message_html = html.escape(message).replace('\n', '<br>') if message else ''
        sharer_name_safe = html.escape(sharer_name)
        track_title_safe = html.escape(track_title)
        book_title_safe = html.escape(book_title)

        email_html = f"""
        <html>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #1a1a2e; color: #e0e0e0; padding: 40px 20px;">
          <div style="max-width: 520px; margin: 0 auto; background: #16213e; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 32px rgba(0,0,0,0.3);">
            <div style="background: linear-gradient(135deg, #e2b714, #f5c518); padding: 24px 28px;">
              <h1 style="margin: 0; color: #1a1a2e; font-size: 22px;">🎧 {sharer_name_safe} shared a chapter with you!</h1>
            </div>
            <div style="padding: 28px;">
              <p style="font-size: 16px; line-height: 1.5; color: #b0b0b0;">Check out <strong style="color: #fff;">"{track_title_safe}"</strong> from <strong style="color: #e2b714;">{book_title_safe}</strong></p>
              {f'<div style="background: rgba(255,255,255,0.05); border-left: 3px solid #e2b714; padding: 12px 16px; margin: 16px 0; border-radius: 0 8px 8px 0;"><em style="color: #ccc;">"{message_html}"</em></div>' if message_html else ''}
              <a href="{share_url}" style="display: inline-block; margin-top: 20px; padding: 14px 32px; background: linear-gradient(135deg, #e2b714, #f5c518); color: #1a1a2e; text-decoration: none; border-radius: 25px; font-weight: bold; font-size: 16px;">▶ Listen Now</a>
              <p style="margin-top: 20px; font-size: 12px; color: #666;">This link expires in 7 days.</p>
            </div>
          </div>
        </body>
        </html>
        """

        email_text = f"{sharer_name} shared \"{track_title}\" from \"{book_title}\" with you!\n\n{message}\n\nListen here: {share_url}\n\nThis link expires in 7 days."

        from email_service import send_user_email
        success, err = send_user_email(friend_email, f"🎧 {sharer_name} shared a chapter with you!", email_html, email_text)

        if not success:
            print(f"Failed to send share email: {err}")
            return jsonify({"error": "Failed to send email", "details": err}), 500

        return jsonify({"message": "Chapter shared successfully", "token": token, "share_url": share_url}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
    finally:
        db.disconnect()





@app.route('/shared/<token>', methods=['GET'])
def shared_web_player(token):
    """Public web player for a shared chapter. No auth required."""
    db = Database()
    if not db.connect():
        return _shared_error_page("Service temporarily unavailable. Please try again later.")
    try:
        # Look up share
        share = db.execute_query(
            "SELECT * FROM shared_chapters WHERE token = %s", (token,)
        )
        if not share:
            return _shared_error_page("This link is invalid or has been removed.")

        share = share[0]

        # Check expiry
        if share['expires_at'] and share['expires_at'] < datetime.datetime.utcnow():
            return _shared_error_page("This link has expired. Ask your friend to share again!")

        # Fetch track info
        track = None
        pid = share['playlist_item_id']
        print(f"[SHARE] Looking up playlist_item_id={pid} for token={token}")

        if pid and pid > 0:
            track_result = db.execute_query(
                "SELECT id, title, file_path, duration_seconds FROM playlist_items WHERE id = %s",
                (pid,)
            )
            if track_result:
                track = track_result[0]

        # Fallback: if no playlist item found, use the book's own audio
        if not track:
            print(f"[SHARE] No playlist item found, falling back to book audio for book_id={share['book_id']}")
            book_fallback = db.execute_query(
                "SELECT id, title, audio_path as file_path, duration_seconds FROM books WHERE id = %s",
                (share['book_id'],)
            )
            if book_fallback:
                track = book_fallback[0]

        if not track:
            return _shared_error_page("The shared chapter could not be found.")

        # Fetch book info
        book = db.execute_query(
            "SELECT title, author, cover_image_path FROM books WHERE id = %s",
            (share['book_id'],)
        )
        book_title = book[0]['title'] if book else 'Audiobook'
        book_author = book[0]['author'] if book else ''
        cover_url = resolve_stored_url(book[0]['cover_image_path'], 'AudioBooks') if book and book[0].get('cover_image_path') else ''

        # Resolve audio URL and append query param for WAF bypass
        base_audio_url = resolve_stored_url(track['file_path'], 'AudioBooks') if track.get('file_path') else ''
        audio_url = f"{base_audio_url}?source=webplayer" if base_audio_url else ''

        # Increment listen count
        db.execute_query(
            "UPDATE shared_chapters SET listen_count = listen_count + 1 WHERE token = %s",
            (token,)
        )

        # Fetch sharer name
        sharer = db.execute_query(
            "SELECT name FROM users WHERE id = %s", (share['sharer_user_id'],)
        )
        sharer_name = sharer[0]['name'] if sharer else 'A friend'

        import html as html_mod
        track_title = html_mod.escape(track['title'] or 'Chapter')
        book_title_safe = html_mod.escape(book_title)
        book_author_safe = html_mod.escape(book_author)
        sharer_name_safe = html_mod.escape(sharer_name)
        message_safe = html_mod.escape(share.get('message') or '')
        duration_seconds = track.get('duration_seconds') or 0
        duration_min = int(duration_seconds) // 60
        duration_sec = int(duration_seconds) % 60

        page_html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{track_title} — {book_title_safe} | Echo</title>
    <meta name="description" content="Listen to '{track_title}' from '{book_title_safe}' — shared by {sharer_name_safe} via Echo.">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .card {{
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(20px);
            border-radius: 24px;
            padding: 40px 32px;
            max-width: 420px;
            width: 100%;
            text-align: center;
            border: 1px solid rgba(255,255,255,0.08);
            box-shadow: 0 20px 60px rgba(0,0,0,0.4);
        }}
        .cover {{
            width: 200px;
            height: 200px;
            border-radius: 16px;
            object-fit: cover;
            margin: 0 auto 24px;
            display: block;
            box-shadow: 0 12px 40px rgba(0,0,0,0.5);
        }}
        .no-cover {{
            width: 200px;
            height: 200px;
            border-radius: 16px;
            margin: 0 auto 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255,255,255,0.08);
            font-size: 64px;
        }}
        .track-title {{
            font-size: 22px;
            font-weight: 700;
            color: #fff;
            margin-bottom: 6px;
        }}
        .book-info {{
            font-size: 14px;
            color: #b0b0b0;
            margin-bottom: 4px;
        }}
        .book-info strong {{ color: #e2b714; }}
        .shared-by {{
            font-size: 13px;
            color: #888;
            margin-bottom: 8px;
        }}
        .message {{
            background: rgba(255,255,255,0.05);
            border-left: 3px solid #e2b714;
            padding: 12px 16px;
            margin: 16px 0;
            border-radius: 0 8px 8px 0;
            font-style: italic;
            color: #ccc;
            text-align: left;
            font-size: 14px;
        }}
        .player-wrapper {{
            margin: 24px 0 16px;
        }}
        audio {{
            width: 100%;
            height: 48px;
            border-radius: 24px;
            outline: none;
        }}
        audio::-webkit-media-controls-panel {{
            background: rgba(255,255,255,0.1);
        }}
        .duration {{
            font-size: 12px;
            color: #666;
            margin-top: 8px;
        }}
        .cta {{
            display: inline-block;
            margin-top: 24px;
            padding: 12px 28px;
            background: linear-gradient(135deg, #e2b714, #f5c518);
            color: #1a1a2e;
            text-decoration: none;
            border-radius: 25px;
            font-weight: 700;
            font-size: 14px;
            transition: transform 0.2s;
        }}
        .cta:hover {{ transform: scale(1.05); }}
        .footer {{
            margin-top: 24px;
            font-size: 11px;
            color: #555;
        }}
    </style>
</head>
<body>
    <div class="card">
        {'<img class="cover" src="' + cover_url + '" alt="Cover">' if cover_url else '<div class="no-cover">🎧</div>'}
        <div class="track-title">{track_title}</div>
        <div class="book-info">from <strong>{book_title_safe}</strong></div>
        {'<div class="book-info">' + book_author_safe + '</div>' if book_author_safe else ''}
        <div class="shared-by">Shared by {sharer_name_safe}</div>
        {'<div class="message">"' + message_safe + '"</div>' if message_safe else ''}
        <div class="player-wrapper">
            <audio controls preload="metadata" src="{audio_url}">
                Your browser does not support audio playback.
            </audio>
        </div>
        <div class="duration">{duration_min}:{duration_sec:02d}</div>
        <div class="footer">Powered by Echo — History Audiobooks</div>
    </div>
</body>
</html>
        """
        return page_html, 200, {'Content-Type': 'text/html; charset=utf-8'}

    except Exception as e:
        import traceback
        traceback.print_exc()
        return _shared_error_page("Something went wrong. Please try again later.")
    finally:
        db.disconnect()


def _shared_error_page(message):
    """Return a styled error page for shared links."""
    import html as html_mod
    msg = html_mod.escape(message)
    return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Echo — Shared Chapter</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .card {{
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(20px);
            border-radius: 24px;
            padding: 48px 32px;
            max-width: 420px;
            width: 100%;
            text-align: center;
            border: 1px solid rgba(255,255,255,0.08);
        }}
        .emoji {{ font-size: 48px; margin-bottom: 16px; }}
        .msg {{ font-size: 16px; color: #ccc; line-height: 1.6; }}
    </style>
</head>
<body>
    <div class="card">
        <div class="emoji">😔</div>
        <div class="msg">{msg}</div>
    </div>
</body>
</html>
    """, 200, {'Content-Type': 'text/html; charset=utf-8'}


if __name__ == '__main__':
    # ... existing main block ...
    pass
