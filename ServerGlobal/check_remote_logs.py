import paramiko
import sys

SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

def check_logs():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected. Fetching logs...")
        
        # Check status
        stdin, stdout, stderr = ssh.exec_command("systemctl status echo_history.service > status.log 2>&1 && cat status.log")
        print("\n--- SERVICE STATUS ---")
        print(stdout.read().decode())
        
        # Check logs
        stdin, stdout, stderr = ssh.exec_command("journalctl -u echo_history.service -n 50 --no-pager > logs.log 2>&1 && cat logs.log")
        print("\n--- RECENT LOGS ---")
        print(stdout.read().decode())
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    check_logs()
