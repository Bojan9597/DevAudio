#!/usr/bin/env python3
"""
Database Migration for Content Encryption Architecture (PostgreSQL version)
This migration adds support for:
1. Content keys for media files (encrypted once per file)
2. Wrapped user keys (per user per device)
3. Encryption metadata (IV, auth tags)
"""
from database import Database

def column_exists(db, table, column):
    """Check if a column exists in a table using PostgreSQL information_schema."""
    result = db.execute_query("""
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = %s AND column_name = %s
        )
    """, (table, column))
    return result and result[0].get('exists', False)

def table_exists(db, table):
    """Check if a table exists using PostgreSQL information_schema."""
    result = db.execute_query("""
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = %s
        )
    """, (table,))
    return result and result[0].get('exists', False)

def migrate():
    db = Database()
    if not db.connect():
        print("Failed to connect to database")
        return False

    try:
        # 1. Add encryption fields to playlist_items table
        print("Adding encryption fields to playlist_items...")

        columns_to_add = [
            ("content_key_encrypted", "BYTEA"),  # PostgreSQL uses BYTEA instead of BLOB
            ("content_iv", "BYTEA"),  # 12 bytes for GCM IV
            ("auth_tag", "BYTEA"),  # 16 bytes for GCM auth tag
            ("encryption_version", "INT DEFAULT NULL"),
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

        if not table_exists(db, 'user_content_keys'):
            create_user_keys = """
                CREATE TABLE user_content_keys (
                    id SERIAL PRIMARY KEY,
                    user_id INT NOT NULL,
                    device_id VARCHAR(255) NOT NULL,
                    media_id INT NOT NULL,
                    wrapped_key BYTEA NOT NULL,
                    wrap_iv BYTEA NOT NULL,
                    wrap_auth_tag BYTEA NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT unique_user_device_media UNIQUE (user_id, device_id, media_id)
                )
            """
            db.execute_query(create_user_keys)
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_user_content_keys_user_device ON user_content_keys(user_id, device_id)")
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_user_content_keys_media ON user_content_keys(media_id)")
            print("  [OK] Table created")
        else:
            print("  [OK] Table already exists")

        # 3. Create server_config table for master secret
        print("\nCreating server_config table...")

        if not table_exists(db, 'server_config'):
            create_config = """
                CREATE TABLE server_config (
                    id SERIAL PRIMARY KEY,
                    config_key VARCHAR(255) UNIQUE NOT NULL,
                    config_value TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """
            db.execute_query(create_config)
            
            # Create trigger for updated_at
            db.execute_query("""
                CREATE OR REPLACE FUNCTION update_server_config_updated_at()
                RETURNS TRIGGER AS $$
                BEGIN
                    NEW.updated_at = CURRENT_TIMESTAMP;
                    RETURN NEW;
                END;
                $$ language 'plpgsql'
            """)
            db.execute_query("DROP TRIGGER IF EXISTS trg_server_config_updated_at ON server_config")
            db.execute_query("""
                CREATE TRIGGER trg_server_config_updated_at
                    BEFORE UPDATE ON server_config
                    FOR EACH ROW
                    EXECUTE FUNCTION update_server_config_updated_at()
            """)
            print("  [OK] Table created")
        else:
            print("  [OK] Table already exists")

        # 4. Create encrypted_files table to track encrypted media
        print("\nCreating encrypted_files table...")

        if not table_exists(db, 'encrypted_files'):
            create_encrypted_files = """
                CREATE TABLE encrypted_files (
                    id SERIAL PRIMARY KEY,
                    original_path VARCHAR(500) NOT NULL,
                    encrypted_path VARCHAR(500) NOT NULL UNIQUE,
                    content_key_encrypted BYTEA NOT NULL,
                    content_iv BYTEA NOT NULL,
                    auth_tag BYTEA NOT NULL,
                    file_size BIGINT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """
            db.execute_query(create_encrypted_files)
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_encrypted_files_original_path ON encrypted_files(original_path)")
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
