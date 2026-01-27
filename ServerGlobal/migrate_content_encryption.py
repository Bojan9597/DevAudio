"""
Database Migration for Content Encryption Architecture
This migration adds support for:
1. Content keys for media files (encrypted once per file)
2. Wrapped user keys (per user per device)
3. Encryption metadata (IV, auth tags)
"""
from database import Database

def column_exists(db, table, column):
    """Check if a column exists in a table."""
    cursor = db.connection.cursor(dictionary=True)
    cursor.execute(f"DESCRIBE {table}")
    columns = cursor.fetchall()
    cursor.close()
    return any(col['Field'] == column for col in columns)

def migrate():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False

    try:
        # 1. Add encryption fields to playlist_items table
        print("Adding encryption fields to playlist_items...")

        # Check and add columns one by one (MySQL doesn't support IF NOT EXISTS for ALTER TABLE)
        columns_to_add = [
            ("content_key_encrypted", "BLOB COMMENT 'Encrypted content key (AES-256-GCM)'"),
            ("content_iv", "BINARY(12) COMMENT 'IV used for content encryption (GCM uses 12 bytes)'"),
            ("auth_tag", "BINARY(16) COMMENT 'GCM authentication tag'"),
            ("encryption_version", "INT DEFAULT NULL COMMENT 'Encryption scheme version'"),
        ]

        for column_name, column_def in columns_to_add:
            if not column_exists(db, 'playlist_items', column_name):
                try:
                    alter_query = f"ALTER TABLE playlist_items ADD COLUMN {column_name} {column_def}"
                    db.execute_query(alter_query)
                    print(f"  [OK] Added column: {column_name}")
                except Exception as e:
                    print(f"  [WARN] Could not add {column_name}: {e}")
            else:
                print(f"  [OK] Column already exists: {column_name}")

        # 2. Create user_content_keys table for wrapped keys
        print("\nCreating user_content_keys table...")

        # First, check if table exists
        cursor = db.connection.cursor()
        cursor.execute("SHOW TABLES LIKE 'user_content_keys'")
        table_exists = cursor.fetchone() is not None
        cursor.close()

        if not table_exists:
            create_user_keys = """
                CREATE TABLE user_content_keys (
                    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                    user_id INT UNSIGNED NOT NULL,
                    device_id VARCHAR(255) NOT NULL,
                    media_id INT UNSIGNED NOT NULL,
                    wrapped_key BLOB NOT NULL COMMENT 'ContentKey wrapped with UserKey',
                    wrap_iv BINARY(12) NOT NULL COMMENT 'IV used for key wrapping',
                    wrap_auth_tag BINARY(16) NOT NULL COMMENT 'GCM auth tag for wrapping',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE KEY unique_user_device_media (user_id, device_id, media_id),
                    INDEX idx_user_device (user_id, device_id),
                    INDEX idx_media (media_id)
                )
            """
            db.execute_query(create_user_keys)
            print("  [OK] Table created")
        else:
            print("  [OK] Table already exists")

        # 3. Create server_config table for master secret
        print("\nCreating server_config table...")
        cursor = db.connection.cursor()
        cursor.execute("SHOW TABLES LIKE 'server_config'")
        table_exists = cursor.fetchone() is not None
        cursor.close()

        if not table_exists:
            create_config = """
                CREATE TABLE server_config (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    config_key VARCHAR(255) UNIQUE NOT NULL,
                    config_value TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """
            db.execute_query(create_config)
            print("  [OK] Table created")
        else:
            print("  [OK] Table already exists")

        # 4. Create encrypted_files table to track encrypted media
        print("\nCreating encrypted_files table...")
        cursor = db.connection.cursor()
        cursor.execute("SHOW TABLES LIKE 'encrypted_files'")
        table_exists = cursor.fetchone() is not None
        cursor.close()

        if not table_exists:
            create_encrypted_files = """
                CREATE TABLE encrypted_files (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    original_path VARCHAR(500) NOT NULL,
                    encrypted_path VARCHAR(500) NOT NULL UNIQUE,
                    content_key_encrypted BLOB NOT NULL,
                    content_iv BINARY(12) NOT NULL,
                    auth_tag BINARY(16) NOT NULL,
                    file_size BIGINT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_original_path (original_path)
                )
            """
            db.execute_query(create_encrypted_files)
            print("  [OK] Table created")
        else:
            print("  [OK] Table already exists")

        print("\n" + "="*60)
        print("Migration completed successfully!")
        print("="*60)
        print("\nNext steps:")
        print("1. Run init_master_secret.py to generate and store the master secret")
        print("2. Run encrypt_existing_files.py to encrypt existing media files")
        print("3. Update client applications to use new encryption flow")

        return True

    except Exception as e:
        print(f"\n[ERROR] Migration failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.disconnect()

if __name__ == "__main__":
    success = migrate()
    exit(0 if success else 1)
