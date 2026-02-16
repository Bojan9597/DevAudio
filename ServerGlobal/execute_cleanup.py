import paramiko
import sys
import time

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"

def run_cleanup():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        sftp = ssh.open_sftp()
        
        # Upload cleanup_users.py
        local_path = "cleanup_users.py"
        remote_path = f"{REMOTE_DIR}/cleanup_users.py"
        print(f"Uploading {local_path} to {remote_path}...")
        sftp.put(local_path, remote_path)
        
        sftp.close()
        print("File uploaded.")

        # Execute Cleanup Script
        print("Running cleanup script on server...")
        cmd = f"cd {REMOTE_DIR} && python3 cleanup_users.py"
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Wait for completion and print output
        exit_status = stdout.channel.recv_exit_status()
        
        print("--- Cleanup Output ---")
        print(stdout.read().decode())
        
        if exit_status != 0:
            print("--- Cleanup Errors ---")
            print(stderr.read().decode())
            print("Cleanup FAILED.")
        else:
            print("Cleanup SUCCESS.")

    except Exception as e:
        print(f"Cleanup execution failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    run_cleanup()
