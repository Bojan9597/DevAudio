#!/usr/bin/env python3
"""
Remove subscriptions by email.
Usage:
    python3 manage_subscription.py <email>    - Remove subscription for specific email
    python3 manage_subscription.py *          - Remove ALL subscriptions except admin
"""

import sys
from database import Database

ADMIN_EMAIL = "bojanpejic97@gmail.com"


def remove_subscription_by_email(email):
    """Remove subscription for a specific user email."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        # Find the user
        result = db.execute_query("SELECT id, name, email FROM users WHERE email = %s", (email,))
        if not result:
            print(f"No user found with email: {email}")
            return

        user = result[0]
        user_id = user['id']
        print(f"Found user: {user['name']} ({user['email']}) [id={user_id}]")

        # Check if they have a subscription
        sub = db.execute_query("SELECT id, plan_type, status, start_date, end_date FROM subscriptions WHERE user_id = %s", (user_id,))
        if not sub:
            print(f"  -> No subscription found for this user.")
            return

        s = sub[0]
        print(f"  -> Subscription: plan={s['plan_type']}, status={s['status']}, start={s['start_date']}, end={s['end_date']}")

        # Delete subscription history first
        hist_count = db.execute_query("DELETE FROM subscription_history WHERE user_id = %s", (user_id,))
        print(f"  -> Deleted {hist_count or 0} history record(s)")

        # Delete subscription
        del_count = db.execute_query("DELETE FROM subscriptions WHERE user_id = %s", (user_id,))
        print(f"  -> Deleted {del_count or 0} subscription(s)")
        print(f"SUCCESS: Subscription removed for {email}")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        db.disconnect()


def remove_all_subscriptions_except_admin():
    """Remove ALL subscriptions except admin."""
    db = Database()
    if not db.connect():
        print("ERROR: Could not connect to database.")
        return

    try:
        # Find admin user id
        admin_result = db.execute_query("SELECT id FROM users WHERE LOWER(email) = LOWER(%s)", (ADMIN_EMAIL,))
        admin_id = admin_result[0]['id'] if admin_result else None

        if admin_id:
            print(f"Admin user id={admin_id} ({ADMIN_EMAIL}) will be KEPT.")
        else:
            print(f"WARNING: Admin email {ADMIN_EMAIL} not found in DB. Deleting ALL subscriptions.")

        # Count before
        count_result = db.execute_query("SELECT COUNT(*) as cnt FROM subscriptions")
        total = count_result[0]['cnt'] if count_result else 0

        if admin_id:
            admin_sub = db.execute_query("SELECT id FROM subscriptions WHERE user_id = %s", (admin_id,))
            admin_has_sub = len(admin_sub) > 0 if admin_sub else False
        else:
            admin_has_sub = False

        to_delete = total - (1 if admin_has_sub else 0)
        print(f"Total subscriptions: {total}, will delete: {to_delete}, keeping admin: {admin_has_sub}")

        if to_delete == 0:
            print("Nothing to delete.")
            return

        # Delete history for non-admin
        if admin_id:
            hist_count = db.execute_query("DELETE FROM subscription_history WHERE user_id != %s", (admin_id,))
            del_count = db.execute_query("DELETE FROM subscriptions WHERE user_id != %s", (admin_id,))
        else:
            hist_count = db.execute_query("DELETE FROM subscription_history")
            del_count = db.execute_query("DELETE FROM subscriptions")

        print(f"Deleted {hist_count or 0} history record(s)")
        print(f"Deleted {del_count or 0} subscription(s)")
        print("SUCCESS: All non-admin subscriptions removed.")

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
        confirm = input("Delete ALL subscriptions except admin? (yes/no): ")
        if confirm.lower() == "yes":
            remove_all_subscriptions_except_admin()
        else:
            print("Cancelled.")
    else:
        remove_subscription_by_email(arg)
