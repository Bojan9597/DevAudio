import subprocess
import sys

def git_push():
    # 1. Get commit message from arguments
    if len(sys.argv) < 2:
        print("Usage: python git_push.py \"Your commit message\"")
        return

    commit_message = sys.argv[1]

    try:
        print("--- Git Push Script ---")
        
        # 2. Add all changes
        print("1. Running: git add .")
        subprocess.run(["git", "add", "."], check=True)

        # 3. Commit
        print(f"2. Running: git commit -m \"{commit_message}\"")
        subprocess.run(["git", "commit", "-m", commit_message], check=True)

        # 4. Push
        print("3. Running: git push -u origin main")
        subprocess.run(["git", "push", "-u", "origin", "main"], check=True)

        print("\n✅ Success! Changes pushed to origin main.")

    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error during git operation: {e}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    git_push()
