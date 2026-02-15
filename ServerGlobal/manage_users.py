#!/usr/bin/env python3
"""
Delete user(s) by email (cascades to subscriptions, books, etc.).
Usage:
    python3 manage_users.py <email>    - Delete a specific user
    python3 manage_users.py *          - Delete ALL users except admin
"""

import sys
from dotenv import load_dotenv
load_dotenv()
from database import Database

ADMIN_EMAIL = "bojanpejic97@gmail.com"


def delete_user_by_email(email):
    """Delete a specific user by email."""
    if email.lower() == ADMIN_EMAIL.lower():
        print(f"ERROR: Cannot delete admin user ({ADMIN_EMAIL}).")
        return

    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        result = db.execute_query("SELECT id, name, email FROM users WHERE email = %s", (email,))
        if not result:
            print(f"No user found with email: {email}")
            return

        user = result[0]
        print(f"Found user: {user['name']} ({user['email']}) [id={user['id']}]")

        # Show related data counts
        sub = db.execute_query("SELECT COUNT(*) as cnt FROM subscriptions WHERE user_id = %s", (user['id'],))
        books = db.execute_query("SELECT COUNT(*) as cnt FROM user_books WHERE user_id = %s", (user['id'],))
        print(f"  -> Subscriptions: {sub[0]['cnt'] if sub else 0}")
        print(f"  -> User books: {books[0]['cnt'] if books else 0}")

        # CASCADE should handle related records
        del_count = db.execute_query("DELETE FROM users WHERE id = %s", (user['id'],))
        print(f"  -> Deleted {del_count or 0} user(s) (cascade deletes related data)")
        print(f"SUCCESS: User {email} deleted.")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def delete_all_users_except_admin():
    """Delete ALL users except admin."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        # Verify admin exists
        admin = db.execute_query("SELECT id, name FROM users WHERE LOWER(email) = LOWER(%s)", (ADMIN_EMAIL,))
        if not admin:
            print(f"WARNING: Admin ({ADMIN_EMAIL}) not found. Aborting to prevent deleting everyone.")
            return

        print(f"Admin: {admin[0]['name']} (id={admin[0]['id']}) - will be KEPT.")

        count = db.execute_query("SELECT COUNT(*) as cnt FROM users WHERE LOWER(email) != LOWER(%s)", (ADMIN_EMAIL,))
        total = count[0]['cnt'] if count else 0
        print(f"Users to delete: {total}")

        if total == 0:
            print("Nothing to delete.")
            return

        del_count = db.execute_query("DELETE FROM users WHERE LOWER(email) != LOWER(%s)", (ADMIN_EMAIL,))
        print(f"Deleted {del_count or 0} user(s) (cascade deletes all related data).")
        print("SUCCESS: All non-admin users removed.")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    arg = sys.argv[1].strip()

    if arg == "*":
        confirm = input("Delete ALL users except admin? (yes/no): ")
        if confirm.lower() == "yes":
            delete_all_users_except_admin()
        else:
            print("Cancelled.")
    else:
        confirm = input(f"Delete user {arg}? (yes/no): ")
        if confirm.lower() == "yes":
            delete_user_by_email(arg)
        else:
            print("Cancelled.")
