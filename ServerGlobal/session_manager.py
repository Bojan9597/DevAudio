from database import Database
from jwt_middleware import blacklist_token
import datetime

class SessionManager:
    def __init__(self):
        self.db = Database()

    def store_session(self, user_id, session_id, refresh_token, device_info=None):
        """
        Stores a new session. 
        Enforces SINGLE SESSION by replacing the entry.
        """
        if not self.db.connect():
            print("SessionManager: DB Connection failed")
            return False

        try:
            # 1. Invalidate old sessions (Single Session Policy)
            self._invalidate_existing_sessions(user_id)

            # 2. Insert new session
            query = """
            INSERT INTO user_sessions (user_id, session_id, refresh_token, expires_at, device_info)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (user_id) DO UPDATE SET 
                session_id = EXCLUDED.session_id,
                refresh_token = EXCLUDED.refresh_token,
                expires_at = EXCLUDED.expires_at,
                created_at = CURRENT_TIMESTAMP
            """
            # Expires in 30 days
            expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=30)
            
            self.db.execute_query(query, (user_id, session_id, refresh_token, expires_at, device_info))
            self.db.connection.commit()
            print(f"Session stored for user {user_id}")
            return True
        except Exception as e:
            print(f"SessionManager Error: {e}")
            return False
        finally:
            self.db.disconnect()

    def check_access_validity(self, user_id, session_id):
        """Check if user_id + session_id match the active session in DB."""
        if not self.db.connect():
            return False
        
        try:
            query = "SELECT id FROM user_sessions WHERE user_id = %s AND session_id = %s"
            res = self.db.execute_query(query, (user_id, session_id))
            return len(res) > 0
        finally:
            self.db.disconnect()

    def remove_session(self, refresh_token):
        """Removes a session by refresh token (used during Logout)"""
        if not self.db.connect():
            return

        try:
            query = "DELETE FROM user_sessions WHERE refresh_token = %s"
            self.db.execute_query(query, (refresh_token,))
            self.db.connection.commit()
            print(f"Session removed for token ...{refresh_token[-10:]}")
        except Exception as e:
            print(f"SessionManager Remove Error: {e}")
        finally:
            self.db.disconnect()

    def _invalidate_existing_sessions(self, user_id):
        """
        Finds existing session for user, adds token to blacklist, calculates remaining expiry.
        """
        # We need to find the OLD token to blacklist it!
        query = "SELECT refresh_token, expires_at FROM user_sessions WHERE user_id = %s"
        results = self.db.execute_query(query, (user_id,))
        
        if results:
            for row in results:
                old_token = row['refresh_token']
                expires_at = row['expires_at']
                
                # Add to blacklist
                print(f"Invalidating old session for user {user_id}")
                blacklist_token(old_token, expires_at)
                
            # Delete rows (though ON DUPLICATE KEY UPDATE might handle it, explicit delete is safer if we change schema)
            # Actually, ON DUPLICATE KEY UPDATE handles the DB row, but we MUST blacklist the old token first.
            # So this method is crucial.
            pass

    def check_session_validity(self, refresh_token):
        """Optional: Check if session exists in DB"""
        if not self.db.connect():
            return False
        
        try:
            query = "SELECT id FROM user_sessions WHERE refresh_token = %s"
            res = self.db.execute_query(query, (refresh_token,))
            return len(res) > 0
        finally:
            self.db.disconnect()
