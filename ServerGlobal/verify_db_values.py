import paramiko
import json

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

CMD = """
su - postgres -c "psql -d velorus_audio -c \\"SELECT * FROM user_books WHERE user_id = 39 OR user_id = 40 ORDER BY updated_at DESC LIMIT 5;\\""
"""
# Note: I am guessing the DB name is 'velorus_audio' or similar. 
# Based on previous SQL dump, it didn't specify DB name in CREATE, but usually it's the default or implied.
# Let's try to list databases first if unsure, or just try 'server_global' or 'postgres'.
# The previous SQL dump file name was `velorusb_DevAudio_pg.sql`.
# Let's try `velorus_audio` or just `postgres`.

def check_db():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        # 1. Find DB Name
        print("Finding databases...")
        stdin, stdout, stderr = ssh.exec_command('su - postgres -c "psql -A -t -c \\"SELECT datname FROM pg_database;\\""')
        dbs = stdout.read().decode()
        print(dbs)
        
        target_db = 'echo_history'
        print(f"Targeting DB: {target_db}")

        # Check if table exists
        print("Checking tables...")
        cmd = f'su - postgres -c "psql -d {target_db} -c \\"\\dt\\""'
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode())
        
        # Query user_books
        print(f"Querying user_books in {target_db}...")
        query = f"SELECT id, user_id, book_id, background_music_id FROM user_books ORDER BY id DESC LIMIT 10;"
        cmd = f'su - postgres -c "psql -d {target_db} -c \\"{query}\\""'
        
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(stdout.read().decode())
        print(stderr.read().decode())

    except Exception as e:
        print(f"Check failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    check_db()
