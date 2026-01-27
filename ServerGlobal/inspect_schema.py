
import sys
import os
sys.path.append(os.path.join(os.getcwd(), 'Server'))
from database import Database

db = Database()
db.connect()
res = db.execute_query("SHOW CREATE TABLE quizzes")

with open("schema_dump.txt", "w") as f:
    f.write(res[0]['Create Table'])

db.disconnect()
