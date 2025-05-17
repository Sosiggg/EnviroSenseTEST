import requests
import time
import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://envirosensedb_user:rkNngiLgzhr6AQlLiywstBPl4gARlKZ5@dpg-d0kapsjuibrs739chbvg-a.singapore-postgres.render.com/envirosensedb")

def test_db_connection():
    """Test the database connection"""
    print("Testing database connection...")

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
        return True
    except Exception as e:
        print(f"Error connecting to PostgreSQL database: {e}")
        return False

def test_register():
    """Test user registration"""
    url = "http://localhost:8000/api/v1/auth/register"
    data = {
        "username": "Sosiggg2",
        "email": "ivi.salski.35+test@gmail.com",
        "password": "admin123"
    }

    print(f"Making request to {url}")
    print(f"Data: {data}")

    try:
        start_time = time.time()
        response = requests.post(url, json=data, timeout=10)
        end_time = time.time()

        print(f"Request took {end_time - start_time:.2f} seconds")
        print(f"Status code: {response.status_code}")
        print(f"Response: {response.text}")
    except requests.exceptions.Timeout:
        print("Request timed out after 10 seconds")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # First test the database connection
    db_ok = test_db_connection()

    if db_ok:
        print("\nDatabase connection is working. Testing registration...")
        test_register()
    else:
        print("\nDatabase connection failed. Fix the database connection before testing registration.")
