"""
Initialize Master Secret for Key Derivation
The master secret is used to derive per-user-per-device keys using HKDF.
This secret must NEVER be exposed to clients.
"""
import os
import secrets
import base64
from database import Database

def generate_master_secret():
    """Generate a cryptographically secure 256-bit master secret."""
    return secrets.token_bytes(32)

def write_to_env_file(master_secret_b64):
    """Write master secret to .env file."""
    env_path = os.path.join(os.path.dirname(__file__), '.env')

    # Check if .env already exists
    if os.path.exists(env_path):
        # Read existing content
        with open(env_path, 'r') as f:
            lines = f.readlines()

        # Update or add MASTER_SECRET
        updated = False
        for i, line in enumerate(lines):
            if line.startswith('MASTER_SECRET='):
                lines[i] = f'MASTER_SECRET={master_secret_b64}\n'
                updated = True
                break

        if not updated:
            lines.append(f'\nMASTER_SECRET={master_secret_b64}\n')

        # Write back
        with open(env_path, 'w') as f:
            f.writelines(lines)
    else:
        # Create new .env file
        with open(env_path, 'w') as f:
            f.write(f'# Content Encryption Master Secret\n')
            f.write(f'# NEVER commit this file to version control!\n')
            f.write(f'MASTER_SECRET={master_secret_b64}\n')

    print(f"[*] Master secret written to .env file")
    print(f"  Location: {env_path}")

def init_master_secret():
    db = Database()

    try:
        # Check if master secret already exists in .env or database
        env_secret = os.getenv('MASTER_SECRET')
        check_query = "SELECT config_value FROM server_config WHERE config_key = 'master_secret'"
        result = db.execute_query(check_query)

        if env_secret or result:
            print("Master secret already exists!")
            if env_secret:
                print("  Location: .env file (environment variable)")
            if result:
                print("  Location: Database (server_config table)")

            # If secret exists in DB but not in .env, write it to .env
            if result and not env_secret:
                print("\n[*] Copying master secret to .env file...")
                write_to_env_file(result[0]['config_value'])

            print("\nWARNING: Do not regenerate this - it will invalidate all user keys!")
            response = input("Do you want to view it? (yes/no): ")
            if response.lower() == 'yes':
                if env_secret:
                    print(f"\nMaster Secret (from .env): {env_secret}")
                elif result:
                    print(f"\nMaster Secret (from database): {result[0]['config_value']}")
            return

        # Generate new master secret
        master_secret = generate_master_secret()
        master_secret_b64 = base64.b64encode(master_secret).decode('utf-8')

        # Store in database (for backward compatibility)
        insert_query = """
            INSERT INTO server_config (config_key, config_value)
            VALUES ('master_secret', %s)
        """
        db.execute_query(insert_query, (master_secret_b64,))
        print("[*] Master secret stored in database")

        # Write to .env file (recommended for production)
        write_to_env_file(master_secret_b64)

        print("\n" + "="*60)
        print("Master secret generated successfully!")
        print("="*60)
        print(f"\nMaster Secret (base64): {master_secret_b64}")
        print("\nIMPORTANT:")
        print("1. [*] Master secret saved to .env file")
        print("2. [*] Master secret saved to database (fallback)")
        print("3. [*] Add .env to .gitignore to prevent committing")
        print("4. [*] Back up this secret securely")
        print("5. [*] Loss of this secret = loss of all user access to content")

    except Exception as e:
        print(f"Error initializing master secret: {e}")
        raise
    finally:
        db.disconnect()

if __name__ == "__main__":
    init_master_secret()
