"""
New API Endpoints for Content Encryption Architecture

These endpoints replace the old per-user encryption with:
1. Serving the same encrypted file to all users
2. Providing user-specific wrapped keys
3. Supporting device-specific key derivation
"""
from flask import jsonify, request, Response, send_file
from database import Database
from content_encryption import ContentEncryptionManager
from jwt_middleware import jwt_required
import os
import base64


def register_encryption_endpoints(app):
    """Register all encryption-related endpoints with the Flask app."""

    @app.route('/v2/encrypted-audio/<path:filepath>')
    @jwt_required
    def serve_encrypted_audio_v2(filepath):
        """
        Serve pre-encrypted audio file (same file for all users).
        The client must request the wrapped key separately.

        Query params:
            - range: Optional byte range (for seeking)

        Returns:
            Encrypted audio file (application/octet-stream)
        """
        user_id = getattr(request, 'user_id', None)
        if not user_id:
            return jsonify({"error": "Authentication required"}), 401

        db = Database()

        try:
            # Build file path - the filepath should now point to encrypted file
            base_dir = os.path.dirname(os.path.abspath(__file__))
            file_path = os.path.join(base_dir, 'static', filepath)

            # Security: ensure path is within static directory
            real_path = os.path.realpath(file_path)
            static_dir = os.path.realpath(os.path.join(base_dir, 'static'))
            if not real_path.startswith(static_dir):
                return jsonify({"error": "Invalid path"}), 403

            if not os.path.exists(file_path):
                return jsonify({"error": "File not found"}), 404

            # Check user has access to this file
            # Extract book info from filepath to verify access
            # This is a simplified check - enhance based on your needs
            query = """
                SELECT pi.book_id
                FROM playlist_items pi
                WHERE pi.file_path = %s
                LIMIT 1
            """
            result = db.execute_query(query, (filepath,))

            if result:
                book_id = result[0]['book_id']
                # Check user access
                from api import has_book_access
                if not has_book_access(user_id, book_id, db):
                    return jsonify({"error": "Access denied"}), 403

            # Handle range requests for seeking
            file_size = os.path.getsize(file_path)
            range_header = request.headers.get('Range')

            if range_header:
                # Parse range header: bytes=start-end
                byte_range = range_header.replace('bytes=', '').split('-')
                start = int(byte_range[0]) if byte_range[0] else 0
                end = int(byte_range[1]) if len(byte_range) > 1 and byte_range[1] else file_size - 1

                with open(file_path, 'rb') as f:
                    f.seek(start)
                    data = f.read(end - start + 1)

                response = Response(
                    data,
                    206,  # Partial Content
                    mimetype='application/octet-stream',
                    headers={
                        'Content-Range': f'bytes {start}-{end}/{file_size}',
                        'Accept-Ranges': 'bytes',
                        'Content-Length': len(data)
                    }
                )
                return response

            # Serve full file
            return send_file(
                file_path,
                mimetype='application/octet-stream',
                as_attachment=True,
                download_name='encrypted_audio.enc'
            )

        except Exception as e:
            print(f"Error serving encrypted audio: {e}")
            return jsonify({"error": str(e)}), 500
        finally:
            db.disconnect()


    @app.route('/v2/content-key/<int:media_id>')
    @jwt_required
    def get_wrapped_content_key(media_id):
        """
        Get the wrapped content key for a specific media item.

        Query params:
            - device_id: Device identifier (required)

        Returns:
            {
                "wrapped_key": "base64_encoded",
                "wrap_iv": "base64_encoded",
                "wrap_auth_tag": "base64_encoded",
                "content_iv": "base64_encoded",
                "auth_tag": "base64_encoded"
            }
        """
        user_id = getattr(request, 'user_id', None)
        if not user_id:
            return jsonify({"error": "Authentication required"}), 401

        device_id = request.args.get('device_id')
        if not device_id:
            return jsonify({"error": "device_id is required"}), 400

        db = Database()
        manager = ContentEncryptionManager(db)

        try:
            # Check user has access to this media
            query = """
                SELECT pi.book_id, pi.content_iv, pi.auth_tag
                FROM playlist_items pi
                WHERE pi.id = %s
            """
            result = db.execute_query(query, (media_id,))

            if not result:
                return jsonify({"error": "Media not found"}), 404

            book_id = result[0]['book_id']
            content_iv = result[0]['content_iv']
            auth_tag = result[0]['auth_tag']

            # Verify user access
            from api import has_book_access
            if not has_book_access(user_id, book_id, db):
                return jsonify({"error": "Access denied"}), 403

            # Get content key (wrapped with master secret)
            key_query = """
                SELECT content_key_encrypted
                FROM playlist_items
                WHERE id = %s
            """
            key_result = db.execute_query(key_query, (media_id,))

            if not key_result or not key_result[0]['content_key_encrypted']:
                return jsonify({"error": "Content key not found"}), 404

            # Unwrap content key using master secret
            master_secret = manager._get_master_secret()
            content_key_encrypted = key_result[0]['content_key_encrypted']

            # The content_key is wrapped with master_secret in a simplified way
            # We need to store wrap_iv and wrap_tag for this too
            # For now, we'll re-wrap it properly

            # Actually, we should retrieve the unwrapped content key
            # This requires adjusting our storage strategy

            # Get or create wrapped key for this user/device
            wrapped_data = manager.get_or_create_wrapped_key(
                user_id,
                device_id,
                media_id,
                None  # We'll need to pass the actual content_key
            )

            return jsonify({
                "wrapped_key": base64.b64encode(wrapped_data['wrapped_key']).decode(),
                "wrap_iv": base64.b64encode(wrapped_data['wrap_iv']).decode(),
                "wrap_auth_tag": base64.b64encode(wrapped_data['wrap_auth_tag']).decode(),
                "content_iv": base64.b64encode(content_iv).decode() if content_iv else None,
                "auth_tag": base64.b64encode(auth_tag).decode() if auth_tag else None
            })

        except Exception as e:
            print(f"Error getting wrapped key: {e}")
            return jsonify({"error": str(e)}), 500
        finally:
            db.disconnect()


    @app.route('/v2/derive-key-params')
    @jwt_required
    def get_key_derivation_params():
        """
        Get parameters needed for client-side key derivation.
        The client can derive their UserKey using HKDF with these parameters.

        Query params:
            - device_id: Device identifier

        Returns:
            {
                "user_id": int,
                "device_id": str,
                "algorithm": "HKDF-SHA256",
                "info": "user_{user_id}:device_{device_id}"
            }

        Note: The client must derive the key using the same KDF as the server.
        The master secret is NEVER sent to the client.
        """
        user_id = getattr(request, 'user_id', None)
        if not user_id:
            return jsonify({"error": "Authentication required"}), 401

        device_id = request.args.get('device_id')
        if not device_id:
            return jsonify({"error": "device_id is required"}), 400

        # Return parameters for key derivation
        # The client will derive the same key using HKDF with these params
        return jsonify({
            "user_id": user_id,
            "device_id": device_id,
            "algorithm": "HKDF-SHA256",
            "key_length": 32,
            "salt_method": "SHA256(user_{user_id})",
            "info": f"user_{user_id}:device_{device_id}",
            "note": "Client must implement HKDF-SHA256 with same parameters"
        })


    @app.route('/v2/encryption-info/<int:media_id>')
    @jwt_required
    def get_encryption_info(media_id):
        """
        Get comprehensive encryption info for a media item.
        This combines file path, wrapped key, and metadata in one response.

        Query params:
            - device_id: Device identifier (required)

        Returns:
            {
                "media_id": int,
                "encrypted_path": str,
                "file_url": str,
                "wrapped_key": "base64",
                "wrap_iv": "base64",
                "wrap_auth_tag": "base64",
                "content_iv": "base64",
                "auth_tag": "base64"
            }
        """
        user_id = getattr(request, 'user_id', None)
        if not user_id:
            return jsonify({"error": "Authentication required"}), 401

        device_id = request.args.get('device_id')
        if not device_id:
            return jsonify({"error": "device_id is required"}), 400

        db = Database()
        manager = ContentEncryptionManager(db)

        try:
            # Get media info
            query = """
                SELECT pi.book_id, pi.file_path, pi.content_iv, pi.auth_tag,
                       pi.content_key_encrypted
                FROM playlist_items pi
                WHERE pi.id = %s
            """
            result = db.execute_query(query, (media_id,))

            if not result:
                return jsonify({"error": "Media not found"}), 404

            media = result[0]

            # Verify user access
            from api import has_book_access
            if not has_book_access(user_id, media['book_id'], db):
                return jsonify({"error": "Access denied"}), 403

            # Get wrapped key (this will need the actual content_key)
            # For now, retrieve from user_content_keys table
            wrapped_query = """
                SELECT wrapped_key, wrap_iv, wrap_auth_tag
                FROM user_content_keys
                WHERE user_id = %s AND device_id = %s AND media_id = %s
            """
            wrapped_result = db.execute_query(wrapped_query, (user_id, device_id, media_id))

            if not wrapped_result:
                return jsonify({"error": "Wrapped key not found. File may not be encrypted yet."}), 404

            wrapped = wrapped_result[0]

            # Build file URL
            from api import BASE_URL
            file_url = f"{BASE_URL}v2/encrypted-audio/{media['file_path']}"

            return jsonify({
                "media_id": media_id,
                "encrypted_path": media['file_path'],
                "file_url": file_url,
                "wrapped_key": base64.b64encode(wrapped['wrapped_key']).decode(),
                "wrap_iv": base64.b64encode(wrapped['wrap_iv']).decode(),
                "wrap_auth_tag": base64.b64encode(wrapped['wrap_auth_tag']).decode(),
                "content_iv": base64.b64encode(media['content_iv']).decode() if media['content_iv'] else None,
                "auth_tag": base64.b64encode(media['auth_tag']).decode() if media['auth_tag'] else None
            })

        except Exception as e:
            print(f"Error getting encryption info: {e}")
            return jsonify({"error": str(e)}), 500
        finally:
            db.disconnect()


    print("✓ Encryption endpoints (v2) registered")
