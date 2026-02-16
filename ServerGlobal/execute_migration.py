import paramiko
import sys
import time

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"

def run_migration():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        sftp = ssh.open_sftp()
        
        # Upload migrate_streaks.py
        local_path = "migrate_streaks.py"
        remote_path = f"{REMOTE_DIR}/migrate_streaks.py"
        print(f"Uploading {local_path} to {remote_path}...")
        sftp.put(local_path, remote_path)
        
        sftp.close()
        print("File uploaded.")

        # Execute Migration Script
        print("Running migration script on server...")
        # Use python3 and ensure we are in the correct directory so imports work
        cmd = f"cd {REMOTE_DIR} && python3 migrate_streaks.py"
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Wait for completion and print output
        exit_status = stdout.channel.recv_exit_status()
        
        print("--- Migration Output ---")
        print(stdout.read().decode())
        
        if exit_status != 0:
            print("--- Migration Errors ---")
            print(stderr.read().decode())
            print("Migration FAILED.")
        else:
            print("Migration SUCCESS.")

    except Exception as e:
        print(f"Migration execution failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    run_migration()
