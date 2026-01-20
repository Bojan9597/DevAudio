from functools import wraps
from flask import request, jsonify
from jwt_config import verify_token
from database import Database
import datetime

def is_token_blacklisted(token):
    """Check if token is in blacklist."""
    db = Database()
    if not db.connect():
        # Fail safe: if DB is down, assume token valid? Or invalid?
        # Better safe: invalid. But let's log error.
        print("Database connection failed during blacklist check")
        return False # Assume valid to avoid lockout during DB hiccups, or True? 

    query = "SELECT id FROM token_blacklist WHERE token = %s"
    result = db.execute_query(query, (token,))
    db.disconnect()
    
    return len(result) > 0 if result else False

def blacklist_token(token, expires_at):
    """Add token to blacklist table."""
    db = Database()
    if not db.connect():
        print("Database connection failed during blacklist insert")
        return

    query = "INSERT INTO token_blacklist (token, expires_at) VALUES (%s, %s)"
    try:
        cursor = db.connection.cursor()
        cursor.execute(query, (token, expires_at))
        db.connection.commit()
        cursor.close()
    except Exception as e:
        print(f"Error blacklisting token: {e}")
    finally:
        db.disconnect()

def jwt_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        
        if not auth_header:
            return jsonify({"error": "Authorization header is missing"}), 401
        
        try:
            # Format: "Bearer <token>"
            token_parts = auth_header.split()
            if len(token_parts) != 2 or token_parts[0].lower() != 'bearer':
                 return jsonify({"error": "Invalid Authorization header format"}), 401
            
            token = token_parts[1]
            
            # Check blacklist
            if is_token_blacklisted(token):
                return jsonify({"error": "Token has been revoked"}), 401

            # Verify token and get payload
            payload = verify_token(token)
            
            if payload['type'] != 'access':
                 return jsonify({"error": "Invalid token type"}), 401

            # Strict Single Session Enforcement
            # Check if session_id in token matches the one in DB
            session_id = payload.get('session_id')
            user_id = payload.get('user_id')
            
            if not session_id:
                # Old token or invalid generation - Reject for strictness
                return jsonify({"error": "Invalid session (legacy token)"}), 401
                
            # Verify against DB
            db = Database()
            if db.connect():
                try:
                    # Check if this specific session is the active one
                    query = "SELECT id FROM user_sessions WHERE user_id = %s AND session_id = %s"
                    res = db.execute_query(query, (user_id, session_id))
                    if not res:
                        # Session replaced or invalid
                        return jsonify({"error": "Session expired (logged in elsewhere)"}), 401
                except Exception as e:
                    print(f"Session check error: {e}")
                    # Fail open or closed? Closed for security.
                    return jsonify({"error": "Session verification failed"}), 401
                finally:
                    db.disconnect()

            # Determine behavior: 
            # Ideally, we pass user_id to the route, but Flask routes expect specific args.
            # We can attach it to request config or verify user_id match if provided in args.
            # For now, we trust the token. If route needs user_id, it can get it from args or we can enforce match.
            # Let's check if 'user_id' is in request args or json, and ensure it matches token?
            # Or just let the route handle it.
            
            # Important: Some routes (like /user-books/<user_id>) have user_id in URL.
            # We should verify that token.user_id == URL.user_id to prevent accessing others' data.
            
            # Extract user_id from path kwargs if present
            url_user_id = kwargs.get('user_id')
            if url_user_id and int(url_user_id) != int(payload['user_id']):
                 return jsonify({"error": "Unauthorized access to this user/resource"}), 403
            
            # Also check query params or body if critical?
            # For now, URL param check is good for GET requests.
            # For POST, we might need manual check inside route or inspect request.json.

            # Store user_id on request object so routes can access it
            request.user_id = user_id

        except Exception as e:
            return jsonify({"error": str(e)}), 401

        return f(*args, **kwargs)
    return decorated_function
