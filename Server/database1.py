import mysql.connector
from mysql.connector import Error

class Database:
    def __init__(self):
        self.host = "hope.global.ba"
        self.database = "velorusb_DevAudio"
        self.user = "velorusb_audio"
        self.password = "Pijanista123!"
        self.connection = None

    def connect(self):
        """Establishes a connection to the database."""
        try:
            self.connection = mysql.connector.connect(
                host=self.host,
                database=self.database,
                user=self.user,
                password=self.password
            )
            if self.connection.is_connected():
                return True
        except Error as e:
            print(f"Error while connecting to MySQL: {e}")
            return False

    def disconnect(self):
        """Closes the connection if it is open."""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("MySQL connection is closed")

    def execute_query(self, query, params=None):
        """Executes a query and returns the results for SELECT queries."""
        if not self.connection or not self.connection.is_connected():
             if not self.connect():
                 return None
        
        cursor = self.connection.cursor(dictionary=True)
        try:
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            if query.strip().upper().startswith(("SELECT", "SHOW")):
                result = cursor.fetchall()
                return result
            else:
                self.connection.commit()
                return cursor.rowcount
        except Error as e:
            print(f"Error executing query: {e}")
            return None
        finally:
            cursor.close()
