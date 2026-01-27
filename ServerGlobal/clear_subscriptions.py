from database import Database

def clear_subscriptions():
    db = Database()
    if not db.connect():
        print("Failed to connect")
        return

    print("Clearing subscription tables...")
    cursor = db.connection.cursor()

    try:
        # Clear subscription history first (has FK to subscriptions)
        cursor.execute("DELETE FROM subscription_history")
        print("Cleared subscription_history")

        # Clear subscriptions
        cursor.execute("DELETE FROM subscriptions")
        print("Cleared subscriptions")

        db.connection.commit()
        print("All subscriptions removed successfully!")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        cursor.close()
        db.disconnect()

if __name__ == "__main__":
    clear_subscriptions()
