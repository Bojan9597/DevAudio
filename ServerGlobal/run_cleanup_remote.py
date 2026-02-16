import paramiko
import sys
import time
import os

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"
SCRIPT_NAME = "delete_non_admin_users.py"

def deploy_and_run():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        sftp = ssh.open_sftp()
        
        # Upload script
        local_path = SCRIPT_NAME
        remote_path = f"{REMOTE_DIR}/{SCRIPT_NAME}"
        
        if not os.path.exists(local_path):
             print(f"Error: {local_path} not found locally.")
             return

        print(f"Uploading {local_path} to {remote_path}...")
        sftp.put(local_path, remote_path)
            
        sftp.close()
        print("File uploaded.")

        # Run script
        print(f"Executing {SCRIPT_NAME} on remote server...")
        # We need to make sure we use the right python environment. 
        # Assuming 'python3' or 'python' is available and has dependencies installed (which they should be for the app)
        stdin, stdout, stderr = ssh.exec_command(f"cd {REMOTE_DIR} && python3 {SCRIPT_NAME}")
        
        # Stream output
        while True:
            line = stdout.readline()
            if not line:
                break
            print(line.strip())
            
        exit_status = stdout.channel.recv_exit_status()
        
        if exit_status == 0:
            print("Cleanup executed successfully.")
        else:
            print("Cleanup failed.")
            print("Error output:")
            print(stderr.read().decode())

    except Exception as e:
        print(f"Operation failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    deploy_and_run()
