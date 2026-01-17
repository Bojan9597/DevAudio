from database import Database

db = Database()
if db.connect():
    res = db.execute_query("SELECT id, category, name, code, threshold FROM badges ORDER BY category, threshold")
    print("Badges in database:")
    for r in res:
        print(f"  [{r['category']}] {r['name']} (code: {r['code']}, threshold: {r['threshold']})")
    print(f"\nTotal: {len(res)} badges")
    db.disconnect()
