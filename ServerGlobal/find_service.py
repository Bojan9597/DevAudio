import paramiko

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

def find_service():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        print("\n--- Searching for service file ---")
        # Grep for the project directory in systemd files
        cmd = "grep -r '/var/www/server_global' /etc/systemd/system/"
        stdin, stdout, stderr = ssh.exec_command(cmd)
        output = stdout.read().decode()
        print(output)
        
        if not output:
             print("No service file found containing the project path via grep.")
             # Try simple listing again just in case
             stdin, stdout, stderr = ssh.exec_command("ls /etc/systemd/system/*.service")
             print("\nListing .service files:")
             print(stdout.read().decode())

    except Exception as e:
        print(f"Search failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    find_service()
