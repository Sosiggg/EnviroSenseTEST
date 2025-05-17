import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://envirosensedb_user:rkNngiLgzhr6AQlLiywstBPl4gARlKZ5@dpg-d0kapsjuibrs739chbvg-a.singapore-postgres.render.com/envirosensedb")

# Parse the connection string
conn_parts = DATABASE_URL.replace("postgresql://", "").split("@")
user_pass = conn_parts[0].split(":")
host_db = conn_parts[1].split("/")
host_port = host_db[0].split(":")

user = user_pass[0]
password = user_pass[1]
host = host_port[0]
port = host_port[1] if len(host_port) > 1 else "5432"
database = host_db[1]

print(f"Connecting to PostgreSQL database: {host}/{database}")

try:
    # Connect to the database
    conn = psycopg2.connect(
        host=host,
        database=database,
        user=user,
        password=password,
        port=port
    )
    
    # Create a cursor
    cur = conn.cursor()
    
    # Execute a test query
    cur.execute("SELECT version();")
    
    # Fetch the result
    version = cur.fetchone()
    print(f"PostgreSQL version: {version[0]}")
    
    # Close the cursor and connection
    cur.close()
    conn.close()
    
    print("Connection successful!")
except Exception as e:
    print(f"Error connecting to PostgreSQL database: {e}")
