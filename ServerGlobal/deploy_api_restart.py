import paramiko

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

def restart_service():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        print("Restarting echo_history service...")
        stdin, stdout, stderr = ssh.exec_command("systemctl restart echo_history")
        exit_status = stdout.channel.recv_exit_status()
        
        if exit_status == 0:
            print("Service restarted successfully.")
        else:
            print("Failed to restart service.")
            print("Error:")
            print(stderr.read().decode())

    except Exception as e:
        print(f"Restart failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    restart_service()
