import jwt
import os
import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'default-fallback-secret-key')
ACCESS_TOKEN_EXPIRE_HOURS = float(os.getenv('JWT_ACCESS_TOKEN_EXPIRES_HOURS', 1))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv('JWT_REFRESH_TOKEN_EXPIRES_DAYS', 30))

def generate_access_token(user_id, session_id):
    """Generate a short-lived access token."""
    payload = {
        'user_id': user_id,
        'session_id': session_id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS),
        'iat': datetime.datetime.utcnow(),
        'type': 'access'
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def generate_refresh_token(user_id, session_id):
    """Generate a long-lived refresh token."""
    payload = {
        'user_id': user_id,
        'session_id': session_id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
        'iat': datetime.datetime.utcnow(),
        'type': 'refresh'
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def verify_token(token):
    """Verify a token and return its payload."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception('Token has expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')
