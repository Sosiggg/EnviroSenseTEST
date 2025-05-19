import os
import psycopg2
from dotenv import load_dotenv
import sys

# Load environment variables
load_dotenv()

# Get database connection details from environment variables
host = os.getenv("POSTGRES_HOST", "dpg-cqvnvvf6fquc73f1iqg0-a.oregon-postgres.render.com")
database = os.getenv("POSTGRES_DB", "envirosense_db")
db_user = os.getenv("POSTGRES_USER", "envirosense_db_user")
db_password = os.getenv("POSTGRES_PASSWORD", "Ij9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9")
port = os.getenv("POSTGRES_PORT", "5432")

def list_users():
    """List all users in the database"""
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=host,
            database=database,
            user=db_user,
            password=db_password,
            port=port
        )

        # Create a cursor
        cur = conn.cursor()

        # Execute a query to get all users
        cur.execute("SELECT id, username, email, is_active FROM users;")

        # Fetch all results
        users = cur.fetchall()

        # Print the results
        print("Users in the database:")
        print("ID | Username | Email | Active")
        print("-" * 50)
        for user in users:
            print(f"{user[0]} | {user[1]} | {user[2]} | {user[3]}")

        # Close the cursor and connection
        cur.close()
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

def reset_password(username, new_password):
    """Reset a user's password"""
    from passlib.context import CryptContext

    # Password hashing
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    # Hash the new password
    hashed_password = pwd_context.hash(new_password)

    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=host,
            database=database,
            user=db_user,
            password=db_password,
            port=port
        )

        # Create a cursor
        cur = conn.cursor()

        # Execute a query to update the user's password
        cur.execute(
            "UPDATE users SET hashed_password = %s WHERE username = %s RETURNING id;",
            (hashed_password, username)
        )

        # Commit the transaction
        result = cur.fetchone()
        conn.commit()

        # Check if the user was found
        if result:
            print(f"Password reset successful for user {username} (ID: {result[0]})")
        else:
            print(f"User {username} not found")

        # Close the cursor and connection
        cur.close()
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

def reset_username(old_username, new_username):
    """Reset a user's username"""
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=host,
            database=database,
            user=db_user,
            password=db_password,
            port=port
        )

        # Create a cursor
        cur = conn.cursor()

        # Execute a query to update the user's username
        cur.execute(
            "UPDATE users SET username = %s WHERE username = %s RETURNING id;",
            (new_username, old_username)
        )

        # Commit the transaction
        result = cur.fetchone()
        conn.commit()

        # Check if the user was found
        if result:
            print(f"Username changed from {old_username} to {new_username} (ID: {result[0]})")
        else:
            print(f"User {old_username} not found")

        # Close the cursor and connection
        cur.close()
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python check_users.py list")
        print("  python check_users.py reset_password <username> <new_password>")
        print("  python check_users.py reset_username <old_username> <new_username>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "list":
        list_users()
    elif command == "reset_password" and len(sys.argv) == 4:
        reset_password(sys.argv[2], sys.argv[3])
    elif command == "reset_username" and len(sys.argv) == 4:
        reset_username(sys.argv[2], sys.argv[3])
    else:
        print("Invalid command or missing arguments")
        print("Usage:")
        print("  python check_users.py list")
        print("  python check_users.py reset_password <username> <new_password>")
        print("  python check_users.py reset_username <old_username> <new_username>")
