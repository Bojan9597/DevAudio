from database import Database

def main():
    db = Database()
    if db.connect():
        print("Connected. Creating subscriptions table...")
        try:
            # Create subscriptions table
            query = """
            CREATE TABLE IF NOT EXISTS subscriptions (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                user_id INT UNSIGNED NOT NULL UNIQUE,
                plan_type ENUM('test_minute', 'monthly', 'yearly', 'lifetime') NOT NULL DEFAULT 'monthly',
                status ENUM('active', 'expired', 'cancelled') NOT NULL DEFAULT 'active',
                start_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                end_date TIMESTAMP NULL,
                auto_renew BOOLEAN DEFAULT TRUE,
                payment_provider VARCHAR(50) NULL,
                external_subscription_id VARCHAR(255) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_status (user_id, status),
                INDEX idx_end_date (end_date)
            )
            """
            db.execute_query(query)
            print("Table 'subscriptions' created or already exists.")

            # Add test_minute to plan_type ENUM if not present (for existing tables)
            alter_query = """
            ALTER TABLE subscriptions
            MODIFY COLUMN plan_type ENUM('test_minute', 'monthly', 'yearly', 'lifetime') NOT NULL DEFAULT 'monthly'
            """
            try:
                db.execute_query(alter_query)
                print("Updated subscriptions plan_type ENUM to include 'test_minute'.")
            except Exception as alter_e:
                print(f"ENUM already includes test_minute or error: {alter_e}")

            # Create subscription_history table for audit trail
            history_query = """
            CREATE TABLE IF NOT EXISTS subscription_history (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                user_id INT UNSIGNED NOT NULL,
                action ENUM('subscribed', 'renewed', 'cancelled', 'expired', 'upgraded', 'downgraded') NOT NULL,
                plan_type ENUM('test_minute', 'monthly', 'yearly', 'lifetime') NULL,
                action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                notes TEXT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_action (user_id, action_date)
            )
            """
            db.execute_query(history_query)
            print("Table 'subscription_history' created or already exists.")

            # Add test_minute to history plan_type ENUM if not present
            alter_history_query = """
            ALTER TABLE subscription_history
            MODIFY COLUMN plan_type ENUM('test_minute', 'monthly', 'yearly', 'lifetime') NULL
            """
            try:
                db.execute_query(alter_history_query)
                print("Updated subscription_history plan_type ENUM to include 'test_minute'.")
            except Exception as alter_e:
                print(f"History ENUM already includes test_minute or error: {alter_e}")

        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect.")

if __name__ == "__main__":
    main()
