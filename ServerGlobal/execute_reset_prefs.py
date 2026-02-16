import paramiko
import sys
import time

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"

def run_reset_prefs():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        sftp = ssh.open_sftp()
        
        # Upload reset_prefs.py
        local_path = "reset_prefs.py"
        remote_path = f"{REMOTE_DIR}/reset_prefs.py"
        print(f"Uploading {local_path} to {remote_path}...")
        sftp.put(local_path, remote_path)
        
        sftp.close()
        print("File uploaded.")

        # Execute Script
        print("Running reset_prefs script on server...")
        cmd = f"cd {REMOTE_DIR} && python3 reset_prefs.py"
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Wait for completion and print output
        exit_status = stdout.channel.recv_exit_status()
        
        print("--- Output ---")
        print(stdout.read().decode())
        
        if exit_status != 0:
            print("--- Errors ---")
            print(stderr.read().decode())
            print("Execution FAILED.")
        else:
            print("Execution SUCCESS.")

    except Exception as e:
        print(f"Execution failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    run_reset_prefs()
