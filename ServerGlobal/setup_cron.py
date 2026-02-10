# Cron Job Setup Script
# This script adds a cron job to run the trigger-daily-emails endpoint every minute.

import os
import sys

def setup_cron():
    # 1. Define the command to run
    # We use curl to hit the local endpoint. 
    # Since it requires Admin, we need a way to authenticate or valid token.
    # Alternatively, we can make a CLI script that imports api.py and runs the function directly.
    
    # Better approach: Create a CLI entry point in api.py or a separate script
    # to avoid needing HTTP/JWT for the cron job itself.
    
    print("Setting up cron job...")
    
    cron_command = "* * * * * cd /var/www/server_global && ./venv/bin/python trigger_emails_cli.py >> /var/log/echo_cron.log 2>&1"
    
    # Append to crontab
    os.system(f"(crontab -l 2>/dev/null; echo '{cron_command}') | crontab -")
    print("Cron job added.")

if __name__ == "__main__":
    setup_cron()
