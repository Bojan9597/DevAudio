import sys
from database import Database

def main():
    db = Database()
    
    print("Attempting to connect to database...")
    if db.connect():
        print(f"Successfully connected to the database: {db.database}")
        
        # Test query to check if tables exist
        tables = db.execute_query("SHOW TABLES")
        print("\nTables in database:")
        for table in tables:
            print(f"- {list(table.values())[0]}")
            
        db.disconnect()
        sys.exit(0)
    else:
        print("Failed to connect to the database.")
        sys.exit(1)

if __name__ == "__main__":
    main()
