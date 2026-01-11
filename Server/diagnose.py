import mysql.connector
from badge_service import BadgeService

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Pijanista123!",
        database="audiobooks"
    )

def diagnose():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    print("\n--- DIAGNOSTICS START ---")

    # 1. Check Badges Table
    cursor.execute("SELECT * FROM badges")
    badges = cursor.fetchall()
    print(f"\n[Badges Table] Found {len(badges)} badges.")
    for b in badges:
        print(f"  - {b['name']} ({b['code']}): Threshold {b['threshold']}")

    # 2. Check User Books (Stats source)
    # Get all users
    cursor.execute("SELECT id, name, email FROM users")
    users = cursor.fetchall()
    print(f"\n[Users] Found {len(users)} users.")

    for user in users:
        print(f"\nScanning User: {user['name']} (ID: {user['id']})")
        
        # Check User Books
        cursor.execute("SELECT * FROM user_books WHERE user_id = %s", (user['id'],))
        ubooks = cursor.fetchall()
        print(f"  - User has {len(ubooks)} books in library.")
        read_count = sum(1 for b in ubooks if b['is_read'])
        print(f"  - Books Read: {read_count}")
        print(f"  - Books Bought: {len(ubooks)}")
        
        # Check User Badges (Existing)
        cursor.execute("SELECT ub.earned_at, b.name FROM user_badges ub JOIN badges b ON ub.badge_id = b.id WHERE ub.user_id = %s", (user['id'],))
        ubadges = cursor.fetchall()
        print(f"  - Earned Badges: {[b['name'] for b in ubadges]}")

        # Run Manual Check Logic
        stats = {
            'books_completed': read_count,
            'books_bought': len(ubooks)
        }
        print(f"  - Calculated Stats: {stats}")
        
        # Check logic against unearned
        for badge in badges:
            earned = any(existing['name'] == badge['name'] for existing in ubadges)
            if not earned:
                # Calculate
                val = 0
                if badge['code'].startswith('read_'): val = stats['books_completed']
                elif badge['code'].startswith('buy_'): val = stats['books_bought']
                
                print(f"    -> Checking '{badge['name']}': Val={val} / Thr={badge['threshold']} -> {'SHOULD EARN' if val >= badge['threshold'] else 'Not yet'}")
                
    conn.close()
    print("\n--- DIAGNOSTICS END ---")

if __name__ == "__main__":
    diagnose()
