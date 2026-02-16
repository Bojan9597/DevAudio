import paramiko
import sys
import time

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"
REMOTE_DIR = "/var/www/server_global"

def deploy():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        sftp = ssh.open_sftp()
        
        # Upload api.py
        local_path = "api.py"
        remote_path = f"{REMOTE_DIR}/api.py"
        print(f"Uploading {local_path} to {remote_path}...")
        sftp.put(local_path, remote_path)
            
        sftp.close()
        print("File uploaded.")

        # Restart Service
        print("Restarting echo_history.service...")
        stdin, stdout, stderr = ssh.exec_command("systemctl restart echo_history.service")
        
        # Wait for completion
        exit_status = stdout.channel.recv_exit_status()
        
        if exit_status == 0:
            print("Service restarted successfully.")
        else:
            print("Service restart failed.")
            print("Error:")
            print(stderr.read().decode())

    except Exception as e:
        print(f"Deployment failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    deploy()
