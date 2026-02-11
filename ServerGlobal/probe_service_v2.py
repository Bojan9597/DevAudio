import paramiko

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

def probe():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        print("\n--- Systemd Service Files ---")
        stdin, stdout, stderr = ssh.exec_command("ls /etc/systemd/system/")
        print(stdout.read().decode())

        print("\n--- Running Python Processes ---")
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep python")
        print(stdout.read().decode())

    except Exception as e:
        print(f"Probe failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    probe()
