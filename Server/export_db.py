import mysql.connector
import os
import datetime
from database import Database

def export_database(output_file="backup.sql"):
    db = Database()
    if not db.connect():
        print("Failed to connect to database.")
        return

    try:
        cursor = db.connection.cursor()
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # Header
            f.write(f"-- AudioBooks Database Backup\n")
            f.write(f"-- Generated: {datetime.datetime.now()}\n\n")
            f.write("SET FOREIGN_KEY_CHECKS=0;\n")
            f.write("SET SQL_MODE = \"NO_AUTO_VALUE_ON_ZERO\";\n")
            f.write("START TRANSACTION;\n")
            f.write("SET time_zone = \"+00:00\";\n\n")

            # Get tables
            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]

            for table_name in tables:
                print(f"Exporting table: {table_name}")
                
                # Drop table
                f.write(f"\n-- --------------------------------------------------------\n")
                f.write(f"-- Table structure for table `{table_name}`\n")
                f.write(f"--\n\n")
                f.write(f"DROP TABLE IF EXISTS `{table_name}`;\n")

                # Create table
                cursor.execute(f"SHOW CREATE TABLE `{table_name}`")
                create_stmt = cursor.fetchone()[1]
                
                # Fix compatibility issues (MySQL 8.0 -> MariaDB/Older MySQL)
                create_stmt = create_stmt.replace("utf8mb4_0900_ai_ci", "utf8mb4_general_ci")
                create_stmt = create_stmt.replace("utf8mb4_0900_as_cs", "utf8mb4_general_ci")
                
                f.write(f"{create_stmt};\n\n")

                # Dump Data
                f.write(f"-- Dumping data for table `{table_name}`\n")
                cursor.execute(f"SELECT * FROM `{table_name}`")
                rows = cursor.fetchall()
                
                if rows:
                    f.write(f"INSERT INTO `{table_name}` VALUES\n")
                    first_row = True
                    for row in rows:
                        if not first_row:
                            f.write(",\n")
                        
                        # Format values
                        values = []
                        for val in row:
                            if val is None:
                                values.append("NULL")
                            elif isinstance(val, (int, float)):
                                values.append(str(val))
                            else:
                                # Escape string
                                val_str = str(val).replace("\\", "\\\\").replace("'", "\\'")
                                values.append(f"'{val_str}'")
                        
                        f.write(f"({', '.join(values)})")
                        first_row = False
                    f.write(";\n")
                else:
                     f.write(f"-- No data for table `{table_name}`\n")

            # Footer
            f.write("\nSET FOREIGN_KEY_CHECKS=1;\n")
            f.write("COMMIT;\n")
            
        print(f"Database exported successfully to {os.path.abspath(output_file)}")

    except mysql.connector.Error as e:
        print(f"Error exporting database: {e}")
    finally:
        if cursor:
            cursor.close()
        db.disconnect()

if __name__ == "__main__":
    export_database("audiobooks_backup.sql")
