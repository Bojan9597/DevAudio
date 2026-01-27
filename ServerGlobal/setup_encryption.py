"""
Encryption Setup Wizard
This script guides you through the complete encryption setup process.
"""
import os
import sys
import subprocess

def print_header(text):
    """Print a section header."""
    print("\n" + "="*60)
    print(text)
    print("="*60)

def print_step(num, text):
    """Print a step number."""
    print(f"\n[Step {num}] {text}")

def run_script(script_name, description):
    """Run a Python script and return success status."""
    print(f"\nRunning: {script_name}")
    print(f"Purpose: {description}")
    print("-" * 60)

    try:
        result = subprocess.run(
            [sys.executable, script_name],
            check=True,
            capture_output=False,
            text=True
        )
        print("-" * 60)
        print(f"✓ {script_name} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print("-" * 60)
        print(f"❌ {script_name} failed")
        return False
    except FileNotFoundError:
        print(f"❌ {script_name} not found")
        return False

def check_dependencies():
    """Check if required Python packages are installed."""
    print("\nChecking dependencies...")

    required = [
        'flask',
        'mysql.connector',
        'cryptography',
        'dotenv',
    ]

    missing = []
    for package in required:
        try:
            if package == 'mysql.connector':
                __import__('mysql.connector')
            elif package == 'dotenv':
                __import__('dotenv')
            else:
                __import__(package)
            print(f"  ✓ {package}")
        except ImportError:
            print(f"  ❌ {package} (missing)")
            missing.append(package)

    if missing:
        print(f"\n⚠ Missing dependencies: {', '.join(missing)}")
        print("\nInstall with: pip install -r requirements.txt")
        return False

    print("\n✓ All dependencies installed")
    return True

def main():
    print_header("Encryption Setup Wizard")

    print("""
This wizard will guide you through setting up the content encryption system.

What this does:
1. Creates database tables for encryption
2. Generates a master secret (stored in .env)
3. Encrypts existing audio files
4. Verifies the setup

Prerequisites:
- MySQL database running
- Python dependencies installed (pip install -r requirements.txt)
- Audio files in static/AudioBooks/
""")

    response = input("\nReady to start? (yes/no): ")
    if response.lower() != 'yes':
        print("Aborted.")
        return

    # Check dependencies
    print_step(0, "Checking dependencies")
    if not check_dependencies():
        print("\n❌ Please install dependencies first:")
        print("   pip install -r requirements.txt")
        return

    # Step 1: Database Migration
    print_step(1, "Database Migration")
    print("Creating required database tables...")

    if not run_script(
        "migrate_content_encryption.py",
        "Create database tables for encryption metadata"
    ):
        print("\n❌ Database migration failed.")
        print("Check that MySQL is running and database credentials are correct.")
        return

    # Step 2: Master Secret Initialization
    print_step(2, "Master Secret Generation")
    print("Generating cryptographically secure master secret...")

    if not run_script(
        "init_master_secret.py",
        "Generate and store master secret in .env file"
    ):
        print("\n❌ Master secret generation failed.")
        return

    # Step 3: File Encryption
    print_step(3, "File Encryption")
    print("Encrypting existing audio files...")
    print("⚠ This may take a while depending on file count and size.")

    if not run_script(
        "encrypt_existing_files.py",
        "Encrypt all audio files with AES-256-GCM"
    ):
        print("\n⚠ File encryption had issues.")
        print("Some files may not have been encrypted. Check the output above.")

    # Step 4: Verification
    print_step(4, "Verification")
    print("Verifying encryption setup...")

    if not run_script(
        "verify_encryption_setup.py",
        "Verify all components are properly configured"
    ):
        print("\n⚠ Verification found issues.")
        print("Review the verification output above to identify problems.")
    else:
        print_header("Setup Complete! 🎉")
        print("""
Your encryption system is now ready!

Next steps:
1. Update your Flutter app to use the new encryption
2. Test audio playback with the new system
3. Deploy to production with HTTPS enabled

Important reminders:
- ✓ Master secret is stored in .env file
- ✓ .env is already in .gitignore
- ⚠ Never commit .env to version control
- ⚠ Back up your master secret securely

To start the server:
  python api.py

For detailed documentation, see:
  - ENCRYPTION_ARCHITECTURE.md
  - ENCRYPTION_SETUP_GUIDE.md
  - QUICK_START.md
""")

if __name__ == "__main__":
    main()
