import paramiko
import os
import sys

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"

# Files to transfer
FILES_TO_UPLOAD = [
    "seed_history_categories.py",
    "requirements.txt" 
]

def deploy():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        sftp = ssh.open_sftp()
        
        # Upload files
        for filename in FILES_TO_UPLOAD:
            local_path = filename
            remote_path = f"{REMOTE_DIR}/{filename}"
            print(f"Uploading {local_path} to {remote_path}...")
            sftp.put(local_path, remote_path)
            
        sftp.close()
        print("Files uploaded.")

        # Execute seed script using server's python environment
        # Assuming venv is at /var/www/server_global/venv (standard pattern)
        # If not, we might need to find it or use python3 directly if global.
        # But usually flask apps use a venv.
        
        # First, ensure connection dependencies are installed
        print("Installing dependencies on server...")
        stdin, stdout, stderr = ssh.exec_command(f"cd {REMOTE_DIR} && venv/bin/pip install -r requirements.txt")
        exit_status = stdout.channel.recv_exit_status()
        if exit_status != 0:
            print("Error installing dependencies:")
            print(stderr.read().decode())
        else:
            print("Dependencies installed.")

        print("Executing seed script...")
        stdin, stdout, stderr = ssh.exec_command(f"cd {REMOTE_DIR} && venv/bin/python seed_history_categories.py")
        
        # Wait for completion
        exit_status = stdout.channel.recv_exit_status()
        
        if exit_status == 0:
            print("Seed script executed successfully.")
            print("Output:")
            print(stdout.read().decode())
        else:
            print("Seed script failed.")
            print("Error:")
            print(stderr.read().decode())
            print("Output:")
            print(stdout.read().decode())

    except Exception as e:
        print(f"Connection failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    deploy()
