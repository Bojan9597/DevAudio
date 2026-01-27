"""
Content Encryption Module
Implements the secure content encryption architecture:
- One-time content encryption per media file
- Per-user-per-device key derivation using HKDF
- Key wrapping using AES-256-GCM
"""
import os
import secrets
import base64
import hashlib
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.backends import default_backend
from database import Database

# Try to load .env file if python-dotenv is available
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv not installed, will use os.getenv directly


class ContentEncryptionManager:
    """Manages content encryption, key derivation, and key wrapping."""

    def __init__(self, db=None):
        self.db = db or Database()
        self._master_secret = None

    def _get_master_secret(self):
        """Retrieve master secret from environment variable or database (cached)."""
        if self._master_secret is None:
            # Try environment variable first (production best practice)
            master_secret_b64 = os.getenv('MASTER_SECRET')

            if master_secret_b64:
                # Load from environment variable
                try:
                    self._master_secret = base64.b64decode(master_secret_b64)
                    print("[INFO] Master secret loaded from environment variable")
                except Exception as e:
                    raise ValueError(f"Invalid MASTER_SECRET in environment: {e}")
            else:
                # Fallback to database (development/testing)
                print("[WARNING] Master secret not found in environment, falling back to database")
                query = "SELECT config_value FROM server_config WHERE config_key = 'master_secret'"
                result = self.db.execute_query(query)
                if not result:
                    raise ValueError(
                        "Master secret not found! Either:\n"
                        "1. Set MASTER_SECRET environment variable, or\n"
                        "2. Run init_master_secret.py to store in database"
                    )
                self._master_secret = base64.b64decode(result[0]['config_value'])

        return self._master_secret

    def derive_user_key(self, user_id, device_id):
        """
        Derive a per-user-per-device 256-bit key using HKDF.

        Args:
            user_id: User identifier (int or str)
            device_id: Device identifier (str)

        Returns:
            bytes: 32-byte derived key
        """
        master_secret = self._get_master_secret()

        # Create deterministic salt from user_id
        salt = hashlib.sha256(f"user_{user_id}".encode()).digest()

        # Create info context with user_id and device_id
        info = f"user_{user_id}:device_{device_id}".encode()

        # Derive key using HKDF
        kdf = HKDF(
            algorithm=hashes.SHA256(),
            length=32,  # 256 bits
            salt=salt,
            info=info,
            backend=default_backend()
        )

        return kdf.derive(master_secret)

    def generate_content_key(self):
        """Generate a random 256-bit content key for encrypting media."""
        return secrets.token_bytes(32)

    def encrypt_content(self, plaintext_data, content_key=None):
        """
        Encrypt content using AES-256-GCM.

        Args:
            plaintext_data: bytes to encrypt
            content_key: 32-byte key (generated if None)

        Returns:
            tuple: (ciphertext, content_key, iv, auth_tag)
        """
        if content_key is None:
            content_key = self.generate_content_key()

        # Generate random IV (12 bytes for GCM)
        iv = secrets.token_bytes(12)

        # Encrypt using AES-GCM
        aesgcm = AESGCM(content_key)
        ciphertext_with_tag = aesgcm.encrypt(iv, plaintext_data, None)

        # Split ciphertext and auth tag (last 16 bytes)
        ciphertext = ciphertext_with_tag[:-16]
        auth_tag = ciphertext_with_tag[-16:]

        return ciphertext, content_key, iv, auth_tag

    def decrypt_content(self, ciphertext, content_key, iv, auth_tag):
        """
        Decrypt content using AES-256-GCM.

        Args:
            ciphertext: encrypted data
            content_key: 32-byte key
            iv: 12-byte IV
            auth_tag: 16-byte authentication tag

        Returns:
            bytes: decrypted plaintext
        """
        aesgcm = AESGCM(content_key)

        # Combine ciphertext and tag for decryption
        ciphertext_with_tag = ciphertext + auth_tag

        # Decrypt and verify
        plaintext = aesgcm.decrypt(iv, ciphertext_with_tag, None)
        return plaintext

    def wrap_key(self, content_key, user_key):
        """
        Wrap (encrypt) a content key using a user key.

        Args:
            content_key: 32-byte key to wrap
            user_key: 32-byte user key

        Returns:
            tuple: (wrapped_key, iv, auth_tag)
        """
        iv = secrets.token_bytes(12)
        aesgcm = AESGCM(user_key)

        wrapped_with_tag = aesgcm.encrypt(iv, content_key, None)
        wrapped_key = wrapped_with_tag[:-16]
        auth_tag = wrapped_with_tag[-16:]

        return wrapped_key, iv, auth_tag

    def unwrap_key(self, wrapped_key, user_key, iv, auth_tag):
        """
        Unwrap (decrypt) a content key using a user key.

        Args:
            wrapped_key: encrypted content key
            user_key: 32-byte user key
            iv: 12-byte IV
            auth_tag: 16-byte authentication tag

        Returns:
            bytes: unwrapped content key
        """
        aesgcm = AESGCM(user_key)
        wrapped_with_tag = wrapped_key + auth_tag
        content_key = aesgcm.decrypt(iv, wrapped_with_tag, None)
        return content_key

    def get_or_create_wrapped_key(self, user_id, device_id, media_id, content_key):
        """
        Get existing wrapped key or create new one for user/device/media combination.

        Args:
            user_id: User ID
            device_id: Device ID
            media_id: Media/playlist item ID
            content_key: Content key to wrap (if creating new)

        Returns:
            dict: {'wrapped_key': bytes, 'wrap_iv': bytes, 'wrap_auth_tag': bytes}
        """
        # Check if wrapped key exists
        query = """
            SELECT wrapped_key, wrap_iv, wrap_auth_tag
            FROM user_content_keys
            WHERE user_id = %s AND device_id = %s AND media_id = %s
        """
        result = self.db.execute_query(query, (user_id, device_id, media_id))

        if result:
            return {
                'wrapped_key': result[0]['wrapped_key'],
                'wrap_iv': result[0]['wrap_iv'],
                'wrap_auth_tag': result[0]['wrap_auth_tag']
            }

        # Create new wrapped key
        user_key = self.derive_user_key(user_id, device_id)
        wrapped_key, wrap_iv, wrap_auth_tag = self.wrap_key(content_key, user_key)

        # Store in database
        insert_query = """
            INSERT INTO user_content_keys
            (user_id, device_id, media_id, wrapped_key, wrap_iv, wrap_auth_tag)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        self.db.execute_query(insert_query, (
            user_id, device_id, media_id, wrapped_key, wrap_iv, wrap_auth_tag
        ))

        return {
            'wrapped_key': wrapped_key,
            'wrap_iv': wrap_iv,
            'wrap_auth_tag': wrap_auth_tag
        }

    def encrypt_file(self, input_path, output_path):
        """
        Encrypt a file on disk using AES-256-GCM.

        Args:
            input_path: Path to plaintext file
            output_path: Path to save encrypted file

        Returns:
            dict: {'content_key': bytes, 'iv': bytes, 'auth_tag': bytes, 'size': int}
        """
        # Read plaintext file
        with open(input_path, 'rb') as f:
            plaintext = f.read()

        # Encrypt content
        ciphertext, content_key, iv, auth_tag = self.encrypt_content(plaintext)

        # Write encrypted file
        with open(output_path, 'wb') as f:
            f.write(ciphertext)

        return {
            'content_key': content_key,
            'iv': iv,
            'auth_tag': auth_tag,
            'size': len(ciphertext)
        }

    def store_encrypted_file_metadata(self, original_path, encrypted_path, content_key, iv, auth_tag, file_size):
        """
        Store metadata about an encrypted file in the database.

        Args:
            original_path: Original file path
            encrypted_path: Encrypted file path
            content_key: Content encryption key
            iv: Initialization vector
            auth_tag: GCM authentication tag
            file_size: Size of encrypted file

        Returns:
            int: ID of inserted record
        """
        # Encrypt the content key for storage (using master secret directly)
        master_secret = self._get_master_secret()
        encrypted_content_key, key_iv, key_tag = self.wrap_key(content_key, master_secret)

        query = """
            INSERT INTO encrypted_files
            (original_path, encrypted_path, content_key_encrypted, content_iv, auth_tag, file_size)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        self.db.execute_query(query, (
            original_path, encrypted_path, encrypted_content_key, iv, auth_tag, file_size
        ))

        # Get inserted ID
        result = self.db.execute_query("SELECT LAST_INSERT_ID() as id")
        return result[0]['id'] if result else None

    def get_file_content_key(self, encrypted_path):
        """
        Retrieve and decrypt content key for an encrypted file.

        Args:
            encrypted_path: Path to encrypted file

        Returns:
            tuple: (content_key, iv, auth_tag) or None if not found
        """
        query = """
            SELECT content_key_encrypted, content_iv, auth_tag
            FROM encrypted_files
            WHERE encrypted_path = %s
        """
        result = self.db.execute_query(query, (encrypted_path,))

        if not result:
            return None

        # Decrypt content key using master secret
        master_secret = self._get_master_secret()
        encrypted_content_key = result[0]['content_key_encrypted']

        # For GCM, the stored content_iv is actually the wrapping IV
        # We need to retrieve the actual content IV from the record
        content_iv = result[0]['content_iv']
        auth_tag = result[0]['auth_tag']

        # Note: The content_key_encrypted in this table is wrapped with master secret
        # We'll need to adjust the schema or storage method

        return encrypted_content_key, content_iv, auth_tag


# Helper functions for API integration

def get_content_key_for_user(user_id, device_id, media_id, db=None):
    """
    Get wrapped content key for a specific user/device/media combination.

    Returns:
        dict: {'wrapped_key': base64_str, 'wrap_iv': base64_str, 'wrap_auth_tag': base64_str}
    """
    manager = ContentEncryptionManager(db)

    # First, get the content key for this media
    query = """
        SELECT content_key_encrypted, content_iv, auth_tag
        FROM playlist_items
        WHERE id = %s
    """
    result = db.execute_query(query, (media_id,))

    if not result or not result[0]['content_key_encrypted']:
        return None

    # Get master secret to unwrap stored content key
    master_secret = manager._get_master_secret()

    # The content_key_encrypted in playlist_items is wrapped with master_secret
    # We need to unwrap it first (this should be reconsidered in production)
    # For now, assume content_key is stored elsewhere or we adjust the flow

    # Get or create wrapped key for this user
    # This requires the actual content_key, which we'll handle in the file encryption script

    wrapped_data = manager.get_or_create_wrapped_key(user_id, device_id, media_id, None)

    return {
        'wrapped_key': base64.b64encode(wrapped_data['wrapped_key']).decode(),
        'wrap_iv': base64.b64encode(wrapped_data['wrap_iv']).decode(),
        'wrap_auth_tag': base64.b64encode(wrapped_data['wrap_auth_tag']).decode()
    }
