import paramiko
import sys
import time
import os

SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"
SCRIPT_NAME = "debug_prefs.py"

def run():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        sftp = ssh.open_sftp()
        
        # Upload
        print(f"Uploading {SCRIPT_NAME}...")
        sftp.put(SCRIPT_NAME, f"{REMOTE_DIR}/{SCRIPT_NAME}")
        sftp.close()

        # Run
        print(f"Executing {SCRIPT_NAME}...")
        stdin, stdout, stderr = ssh.exec_command(f"cd {REMOTE_DIR} && python3 {SCRIPT_NAME} > debug_out.txt 2>&1 && cat debug_out.txt")
        
        print("\n--- OUTPUT ---")
        print(stdout.read().decode())

    finally:
        ssh.close()

if __name__ == "__main__":
    run()
