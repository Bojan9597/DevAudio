"""
Verify Encryption Setup
This script checks if the encryption system is properly configured.
"""
import os
import sys
from database import Database

def check_env_file():
    """Check if .env file exists and contains MASTER_SECRET."""
    env_path = os.path.join(os.path.dirname(__file__), '.env')

    if not os.path.exists(env_path):
        print("❌ .env file not found")
        return False

    with open(env_path, 'r') as f:
        content = f.read()

    if 'MASTER_SECRET=' not in content:
        print("❌ MASTER_SECRET not found in .env")
        return False

    # Check if it's not the example value
    if 'your_base64_master_secret_here' in content:
        print("❌ MASTER_SECRET in .env is still the example value")
        return False

    print("✓ .env file exists with MASTER_SECRET")
    return True

def check_master_secret_env():
    """Check if MASTER_SECRET environment variable is set."""
    master_secret = os.getenv('MASTER_SECRET')

    if not master_secret:
        print("⚠ MASTER_SECRET environment variable not set (will load from .env)")
        return False

    if master_secret == 'your_base64_master_secret_here':
        print("❌ MASTER_SECRET is still the example value")
        return False

    print("✓ MASTER_SECRET environment variable is set")
    return True

def check_database_tables():
    """Check if required database tables exist."""
    db = Database()

    try:
        # Check for required tables
        tables_to_check = [
            'server_config',
            'user_content_keys',
            'encrypted_files',
        ]

        print("\nChecking database tables:")
        all_exist = True

        for table in tables_to_check:
            query = f"SHOW TABLES LIKE '{table}'"
            result = db.execute_query(query)

            if result:
                print(f"  ✓ {table}")
            else:
                print(f"  ❌ {table} (missing)")
                all_exist = False

        # Check for encryption columns in playlist_items
        query = "DESCRIBE playlist_items"
        result = db.execute_query(query)

        encryption_columns = ['content_key_encrypted', 'content_iv', 'auth_tag', 'encryption_version']
        existing_columns = [row['Field'] for row in result] if result else []

        print("\nChecking playlist_items columns:")
        for col in encryption_columns:
            if col in existing_columns:
                print(f"  ✓ {col}")
            else:
                print(f"  ❌ {col} (missing)")
                all_exist = False

        return all_exist

    except Exception as e:
        print(f"❌ Database error: {e}")
        return False
    finally:
        db.disconnect()

def check_master_secret_db():
    """Check if master secret exists in database."""
    db = Database()

    try:
        query = "SELECT config_value FROM server_config WHERE config_key = 'master_secret'"
        result = db.execute_query(query)

        if result and result[0]['config_value']:
            print("✓ Master secret exists in database")
            return True
        else:
            print("❌ Master secret not found in database")
            return False

    except Exception as e:
        print(f"⚠ Cannot check database master secret: {e}")
        return False
    finally:
        db.disconnect()

def check_encrypted_files():
    """Check if any files have been encrypted."""
    db = Database()

    try:
        query = """
            SELECT COUNT(*) as count
            FROM playlist_items
            WHERE encryption_version = 1
        """
        result = db.execute_query(query)

        if result and result[0]['count'] > 0:
            count = result[0]['count']
            print(f"✓ {count} playlist items are encrypted")
            return True
        else:
            print("⚠ No encrypted playlist items found (run encrypt_existing_files.py)")
            return False

    except Exception as e:
        print(f"⚠ Cannot check encrypted files: {e}")
        return False
    finally:
        db.disconnect()

def check_static_encrypted_files():
    """Check if encrypted files exist in static directory."""
    static_dir = os.path.join(os.path.dirname(__file__), 'static', 'AudioBooks')

    if not os.path.exists(static_dir):
        print("⚠ static/AudioBooks directory not found")
        return False

    # Look for files with _encrypted in name
    encrypted_files = []
    for root, dirs, files in os.walk(static_dir):
        for file in files:
            if '_encrypted' in file:
                encrypted_files.append(file)

    if encrypted_files:
        print(f"✓ Found {len(encrypted_files)} encrypted files in static/AudioBooks")
        return True
    else:
        print("⚠ No encrypted files found in static/AudioBooks")
        print("  Run: python encrypt_existing_files.py")
        return False

def main():
    print("="*60)
    print("Encryption Setup Verification")
    print("="*60)
    print()

    checks = [
        ("Environment File", check_env_file),
        ("Environment Variable", check_master_secret_env),
        ("Database Tables", check_database_tables),
        ("Master Secret in DB", check_master_secret_db),
        ("Encrypted Playlist Items", check_encrypted_files),
        ("Encrypted Files on Disk", check_static_encrypted_files),
    ]

    results = []
    for name, check_func in checks:
        print(f"\n{name}:")
        try:
            result = check_func()
            results.append((name, result))
        except Exception as e:
            print(f"  ❌ Error: {e}")
            results.append((name, False))

    print("\n" + "="*60)
    print("Summary")
    print("="*60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✓ PASS" if result else "❌ FAIL"
        print(f"{status:10} {name}")

    print(f"\nPassed: {passed}/{total}")

    if passed == total:
        print("\n🎉 All checks passed! Encryption system is ready.")
        return 0
    else:
        print("\n⚠ Some checks failed. Follow the instructions above to fix.")
        print("\nSetup steps:")
        print("1. Run: python migrate_content_encryption.py")
        print("2. Run: python init_master_secret.py")
        print("3. Run: python encrypt_existing_files.py")
        return 1

if __name__ == "__main__":
    sys.exit(main())
