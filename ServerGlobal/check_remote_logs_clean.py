import paramiko
import sys
import os

SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

def check_logs():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        
        # 1. Generate logs on server
        print("Generating log files on server...")
        ssh.exec_command("journalctl -u echo_history.service -n 50 --no-pager > logs.log 2>&1")
        
        # 2. Download log file
        sftp = ssh.open_sftp()
        print("Downloading logs.log...")
        sftp.get("logs.log", "downloaded_logs.txt")
        sftp.close()
        
        # 3. Read locally
        print("\n--- DOWNLOADED LOGS ---")
        with open("downloaded_logs.txt", "r", encoding="utf-8") as f:
            print(f.read())
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    check_logs()
