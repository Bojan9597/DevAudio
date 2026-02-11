import paramiko
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
        print("api.py uploaded.")

        # Restart Service
        print("Attempting to restart service...")
        # Check for service name
        stdin, stdout, stderr = ssh.exec_command("systemctl list-units --full -all | grep -E 'server_global|gunicorn|flask' | awk '{print $1}'")
        services = stdout.read().decode().strip().split('\n')
        
        service_name = None
        for s in services:
            if "server_global" in s:
                service_name = s
                break
            if "gunicorn" in s:
                service_name = s # Fallback or specific gunicorn service
        
        if not service_name and services:
             # Just pick the first likely one if exact match fails but grep found something
             if services[0]:
                service_name = services[0]

        if service_name:
            print(f"Found service: {service_name}. Restarting...")
            stdin, stdout, stderr = ssh.exec_command(f"systemctl restart {service_name}")
            exit_status = stdout.channel.recv_exit_status()
            if exit_status == 0:
                print(f"Service {service_name} restarted successfully.")
            else:
                print(f"Failed to restart {service_name}. Error: {stderr.read().decode()}")
        else:
            print("Could not detect systemd service name. Please restart manually.")
            print("Found candidates: ", services)

    except Exception as e:
        print(f"Deployment failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    deploy()
