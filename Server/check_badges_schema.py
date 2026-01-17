from database import Database

db = Database()
db.connect()
res = db.execute_query("DESCRIBE badges")
print("Badges table schema:")
for r in res:
    print(f"  {r['Field']}: {r['Type']}")
db.disconnect()
