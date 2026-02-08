import paramiko
import os
from dotenv import load_dotenv

load_dotenv()

# Server Details
# Server Details
# Correct details from deploy_seed.py
HOST = "76.13.140.158"
USER = "root"
PASSWORD = "Pijanista123()"
PORT = 22
REMOTE_DIR = "/var/www/server_global"

def deploy_and_run():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        print(f"Connecting to {HOST}...")
        ssh.connect(HOST, port=PORT, username=USER, password=PASSWORD)
        
        sftp = ssh.open_sftp()
        local_file = "fix_book_categories.py"
        remote_file = f"{REMOTE_DIR}/fix_book_categories.py"
        
        print(f"Uploading {local_file} to {remote_file}...")
        sftp.put(local_file, remote_file)
        sftp.close()
        
        print("Executing remote script...")
        # Use valid python path and ensure env vars are loaded (if .env is processed by python script)
        # We assume .env is already on server from previous steps
        # Also need to make sure we use the venv python
        cmd = f"cd {REMOTE_DIR} && venv/bin/python fix_book_categories.py"
        
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # Stream output
        exit_status = stdout.channel.recv_exit_status() # Wait for finish
        
        print("--- Standard Output ---")
        print(stdout.read().decode())
        
        print("--- Standard Error ---")
        err = stderr.read().decode()
        if err:
            print(err)
            
        if exit_status == 0:
            print("Script executed successfully.")
        else:
            print("Script failed.")
            
    except Exception as e:
        print(f"Connection failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    deploy_and_run()
