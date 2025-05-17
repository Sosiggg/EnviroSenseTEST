import os
import sys
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://envirosensedb_user:rkNngiLgzhr6AQlLiywstBPl4gARlKZ5@dpg-d0kapsjuibrs739chbvg-a.singapore-postgres.render.com/envirosensedb")

def list_users():
    """List all users in the database"""
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
        
        # Execute a query to get all users
        cur.execute("SELECT id, username, email, is_active FROM users;")
        
        # Fetch all results
        users = cur.fetchall()
        
        # Print the users
        print("\nUsers in the database:")
        print("----------------------")
        print(f"{'ID':<5} {'Username':<20} {'Email':<30} {'Active':<10}")
        print("-" * 65)
        
        for user in users:
            user_id, username, email, is_active = user
            print(f"{user_id:<5} {username:<20} {email:<30} {is_active}")
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        
        return users
    except Exception as e:
        print(f"Error connecting to PostgreSQL database: {e}")
        return []

def get_user_sensor_data(user_id):
    """Get sensor data for a specific user"""
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
        
        # Execute a query to get sensor data for the user
        cur.execute("""
            SELECT id, temperature, humidity, obstacle, timestamp 
            FROM sensor_data 
            WHERE user_id = %s 
            ORDER BY timestamp DESC 
            LIMIT 10;
        """, (user_id,))
        
        # Fetch all results
        sensor_data = cur.fetchall()
        
        # Print the sensor data
        print(f"\nLatest sensor data for user ID {user_id}:")
        print("----------------------------------------")
        print(f"{'ID':<5} {'Temperature':<15} {'Humidity':<15} {'Obstacle':<10} {'Timestamp':<25}")
        print("-" * 70)
        
        for data in sensor_data:
            data_id, temperature, humidity, obstacle, timestamp = data
            print(f"{data_id:<5} {temperature:<15.1f} {humidity:<15.1f} {obstacle!s:<10} {timestamp}")
        
        # Get the count of sensor data records
        cur.execute("SELECT COUNT(*) FROM sensor_data WHERE user_id = %s;", (user_id,))
        count = cur.fetchone()[0]
        print(f"\nTotal sensor data records for user ID {user_id}: {count}")
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        
        return sensor_data
    except Exception as e:
        print(f"Error connecting to PostgreSQL database: {e}")
        return []

if __name__ == "__main__":
    # List all users
    users = list_users()
    
    if users:
        # Ask which user to check
        user_id = input("\nEnter user ID to check sensor data (or press Enter to exit): ")
        if user_id:
            try:
                user_id = int(user_id)
                get_user_sensor_data(user_id)
            except ValueError:
                print("Invalid user ID. Please enter a number.")
    else:
        print("No users found in the database.")
