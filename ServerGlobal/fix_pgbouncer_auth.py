import paramiko

SERVER_IP = "76.13.140.158"
SERVER_USER = "root"
SERVER_PASS = "Pijanista123()"

REMOTE_USER = "echo_history_user"
REMOTE_DB = "echo_history"
REMOTE_DB_PASSWORD = "EchoHistory2024SecureDB"
REMOTE_ENV = "/var/www/server_global/.env"


def run_cmd(ssh: paramiko.SSHClient, cmd: str):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode(errors="ignore").strip()
    err = stderr.read().decode(errors="ignore").strip()
    return exit_status, out, err


def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Connecting to {SERVER_IP}...")
    ssh.connect(SERVER_IP, username=SERVER_USER, password=SERVER_PASS)
    print("Connected.")

    try:
        # Fetch SCRAM secret directly from PostgreSQL role metadata.
        q = (
            "su - postgres -c "
            "\"psql -Atqc \\\"SELECT rolpassword FROM pg_authid "
            f"WHERE rolname='{REMOTE_USER}';\\\"\""
        )
        status, secret, err = run_cmd(ssh, q)
        if status != 0 or not secret:
            raise RuntimeError(f"Failed to read rolpassword. err={err}")
        print("Fetched role SCRAM secret.")

        # Update PgBouncer auth file to exact same SCRAM secret.
        escaped = secret.replace('"', '\\"')
        cmd = (
            f"printf '\"{REMOTE_USER}\" \"{escaped}\"\\n' > /etc/pgbouncer/userlist.txt"
        )
        status, out, err = run_cmd(ssh, cmd)
        if status != 0:
            raise RuntimeError(f"Failed to write userlist.txt. err={err}")
        print("Updated /etc/pgbouncer/userlist.txt.")

        # Ensure app env uses PgBouncer.
        cmd = (
            f"if grep -q '^DB_PORT=' {REMOTE_ENV}; then "
            f"sed -i 's/^DB_PORT=.*/DB_PORT=6432/' {REMOTE_ENV}; "
            f"else echo 'DB_PORT=6432' >> {REMOTE_ENV}; fi"
        )
        run_cmd(ssh, cmd)

        # Restart services.
        run_cmd(ssh, "systemctl restart pgbouncer")
        run_cmd(ssh, "systemctl restart echo_history.service")
        print("Restarted pgbouncer and echo_history.service.")

        # Verify PgBouncer path works using app credentials.
        verify = (
            f"PGPASSWORD='{REMOTE_DB_PASSWORD}' psql "
            f"-h 127.0.0.1 -p 6432 -U {REMOTE_USER} -d {REMOTE_DB} "
            "-t -c 'SELECT 1;'"
        )
        status, out, err = run_cmd(ssh, verify)
        if status != 0:
            raise RuntimeError(f"PgBouncer verify failed. err={err}")
        print(f"PgBouncer verification output: {out}")

    finally:
        ssh.close()


if __name__ == "__main__":
    main()
