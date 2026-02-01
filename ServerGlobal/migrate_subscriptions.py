#!/usr/bin/env python3
"""Create the subscriptions and subscription_history tables for PostgreSQL."""

from database import Database

def main():
    db = Database()
    if db.connect():
        print("Connected. Creating subscriptions tables...")
        try:
            # Create subscriptions table
            # PostgreSQL uses VARCHAR with CHECK constraint instead of ENUM
            query = """
            CREATE TABLE IF NOT EXISTS subscriptions (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL UNIQUE,
                plan_type VARCHAR(20) NOT NULL DEFAULT 'monthly' CHECK (plan_type IN ('test_minute', 'monthly', 'yearly', 'lifetime')),
                status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
                start_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                end_date TIMESTAMP NULL,
                auto_renew BOOLEAN DEFAULT TRUE,
                payment_provider VARCHAR(50) NULL,
                external_subscription_id VARCHAR(255) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
            """
            db.execute_query(query)
            print("Table 'subscriptions' created or already exists.")

            # Create indices separately
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status)")
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date ON subscriptions(end_date)")

            # Create trigger for updated_at
            db.execute_query("""
                CREATE OR REPLACE FUNCTION update_subscriptions_updated_at()
                RETURNS TRIGGER AS $$
                BEGIN
                    NEW.updated_at = CURRENT_TIMESTAMP;
                    RETURN NEW;
                END;
                $$ language 'plpgsql'
            """)
            db.execute_query("DROP TRIGGER IF EXISTS trg_subscriptions_updated_at ON subscriptions")
            db.execute_query("""
                CREATE TRIGGER trg_subscriptions_updated_at
                    BEFORE UPDATE ON subscriptions
                    FOR EACH ROW
                    EXECUTE FUNCTION update_subscriptions_updated_at()
            """)

            # Create subscription_history table for audit trail
            history_query = """
            CREATE TABLE IF NOT EXISTS subscription_history (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL,
                action VARCHAR(20) NOT NULL CHECK (action IN ('subscribed', 'renewed', 'cancelled', 'expired', 'upgraded', 'downgraded')),
                plan_type VARCHAR(20) NULL CHECK (plan_type IN ('test_minute', 'monthly', 'yearly', 'lifetime')),
                action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                notes TEXT NULL,
                CONSTRAINT fk_subscription_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
            """
            db.execute_query(history_query)
            print("Table 'subscription_history' created or already exists.")

            # Create index
            db.execute_query("CREATE INDEX IF NOT EXISTS idx_subscription_history_user_action ON subscription_history(user_id, action_date)")

        except Exception as e:
            print(f"Error: {e}")
        finally:
            db.disconnect()
    else:
        print("Failed to connect.")

if __name__ == "__main__":
    main()
