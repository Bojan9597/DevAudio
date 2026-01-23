"""
Encrypt existing audio files with the new content encryption architecture.
This script:
1. Finds all playlist items
2. Encrypts each unique audio file once
3. Stores encryption metadata in database
4. Creates wrapped keys for all users who have access
"""
import os
import base64
from database import Database
from content_encryption import ContentEncryptionManager


def encrypt_existing_files(static_dir='static'):
    """Encrypt all existing audio files in the database."""
    db = Database()
    manager = ContentEncryptionManager(db)

    try:
        # Get all unique audio files from playlist_items
        query = """
            SELECT DISTINCT file_path, id as first_item_id
            FROM playlist_items
            WHERE content_key_encrypted IS NULL OR encryption_version IS NULL
            ORDER BY file_path
        """
        items = db.execute_query(query)

        if not items:
            print("No files to encrypt (all already encrypted or no files found)")
            return

        print(f"Found {len(items)} unique audio files to encrypt\n")

        encrypted_count = 0
        skipped_count = 0

        for item in items:
            file_path = item['file_path']

            # Handle full URLs vs relative paths
            if file_path.startswith('http'):
                # Extract relative path from URL
                # e.g., "http://192.168.100.15:5000/static/AudioBooks/..." -> "AudioBooks/..."
                if '/static/' in file_path:
                    file_path = file_path.split('/static/')[1]
                elif 'AudioBooks/' in file_path:
                    file_path = file_path.split('AudioBooks/')[1]
                    file_path = 'AudioBooks/' + file_path
                else:
                    print(f"[*] Skipping {file_path} (cannot extract relative path)")
                    skipped_count += 1
                    continue

            original_file = os.path.join(static_dir, file_path)

            # Check if file exists
            if not os.path.exists(original_file):
                print(f"[*] Skipping {file_path} (file not found)")
                skipped_count += 1
                continue

            # Create encrypted file path
            dir_path, filename = os.path.split(file_path)
            name, ext = os.path.splitext(filename)
            encrypted_filename = f"{name}_encrypted{ext}"
            encrypted_rel_path = os.path.join(dir_path, encrypted_filename)
            encrypted_file = os.path.join(static_dir, encrypted_rel_path)

            # Ensure directory exists
            os.makedirs(os.path.dirname(encrypted_file), exist_ok=True)

            print(f"Encrypting: {file_path}")

            try:
                # Encrypt the file
                result = manager.encrypt_file(original_file, encrypted_file)

                # Update all playlist_items with this file_path
                update_query = """
                    UPDATE playlist_items
                    SET content_key_encrypted = %s,
                        content_iv = %s,
                        auth_tag = %s,
                        file_path = %s,
                        encryption_version = 1
                    WHERE file_path = %s
                """

                # For playlist_items, we store the content_key wrapped with master secret
                # This is temporary storage; actual user keys are in user_content_keys
                master_secret = manager._get_master_secret()
                wrapped_key, wrap_iv, wrap_tag = manager.wrap_key(result['content_key'], master_secret)

                db.execute_query(update_query, (
                    wrapped_key,
                    result['iv'],
                    result['auth_tag'],
                    encrypted_rel_path,
                    file_path
                ))

                # Now create wrapped keys for all users who have access to books containing this track
                # Get all users with access to books containing these tracks
                users_query = """
                    SELECT DISTINCT ub.user_id, pi.id as media_id
                    FROM user_books ub
                    JOIN playlist_items pi ON pi.book_id = ub.book_id
                    WHERE pi.file_path = %s
                """
                users = db.execute_query(users_query, (encrypted_rel_path,))

                # For each user, create wrapped key (we'll use 'default' as initial device_id)
                for user_media in users:
                    user_id = user_media['user_id']
                    media_id = user_media['media_id']

                    # Create wrapped key for default device
                    try:
                        manager.get_or_create_wrapped_key(
                            user_id,
                            'default',
                            media_id,
                            result['content_key']
                        )
                    except Exception as e:
                        print(f"  Warning: Could not create wrapped key for user {user_id}: {e}")

                encrypted_count += 1
                print(f"[*] Encrypted successfully ({result['size']:,} bytes)")
                print(f"  Created wrapped keys for {len(users)} user/media combinations")

            except Exception as e:
                print(f"[*] Error encrypting {file_path}: {e}")
                skipped_count += 1

        print(f"\n{'='*60}")
        print(f"Encryption complete!")
        print(f"[*] Encrypted: {encrypted_count} files")
        if skipped_count > 0:
            print(f"[*] Skipped: {skipped_count} files")
        print(f"{'='*60}")

        print("\nNext steps:")
        print("1. Test downloading and playing encrypted content")
        print("2. Update client applications to use new key unwrapping flow")
        print("3. (Optional) Delete original unencrypted files after verification")

    except Exception as e:
        print(f"Error during encryption: {e}")
        raise
    finally:
        db.disconnect()


if __name__ == "__main__":
    print("="*60)
    print("Content Encryption Script")
    print("="*60)
    print("\nThis will encrypt all audio files with AES-256-GCM.")
    print("Original files will be kept for now.")
    print()

    response = input("Continue? (yes/no): ")
    if response.lower() == 'yes':
        encrypt_existing_files()
    else:
        print("Aborted.")
