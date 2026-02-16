import paramiko

# Define server details
SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

def check_prefs():
    print(f"Connecting to {SERVER_IP}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
        print("Connected via SSH.")
        
        # Run SQL query
        query = "SELECT id, email, current_streak, last_daily_goal_at, preferences FROM users WHERE email='bojanpejic97@gmail.com';"
        cmd = f"psql -U postgres -d velorusb_DevAudio -c \"{query}\""
        
        print(f"Running query: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        print("--- Query Output ---")
        print(stdout.read().decode())
        
        err = stderr.read().decode()
        if err:
            print("--- Query Errors ---")
            print(err)

    except Exception as e:
        print(f"Execution failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    check_prefs()
