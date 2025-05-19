"""
Script to apply the brute force protection migration directly to the database.
This script connects directly to the database and executes the SQL statements
to add the required columns.
"""
import os
import sys
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get database connection details from environment variables
host = os.getenv("POSTGRES_HOST", "dpg-cqvnvvf6fquc73f1iqg0-a.oregon-postgres.render.com")
database = os.getenv("POSTGRES_DB", "envirosense_db")
db_user = os.getenv("POSTGRES_USER", "envirosense_db_user")
db_password = os.getenv("POSTGRES_PASSWORD", "Ij9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9")
port = os.getenv("POSTGRES_PORT", "5432")

def apply_migration():
    """Apply the brute force protection migration directly to the database."""
    try:
        # Connect to the database
        print(f"Connecting to database {database} on {host}...")
        conn = psycopg2.connect(
            host=host,
            database=database,
            user=db_user,
            password=db_password,
            port=port
        )
        
        # Create a cursor
        cur = conn.cursor()
        
        # Check if the columns already exist
        print("Checking if columns already exist...")
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'failed_login_attempts';
        """)
        
        if cur.fetchone():
            print("Migration already applied. Columns already exist.")
            conn.close()
            return
        
        # Add the new columns
        print("Adding brute force protection columns to users table...")
        
        # Add failed_login_attempts column
        print("Adding failed_login_attempts column...")
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
        """)
        
        # Add last_failed_login column
        print("Adding last_failed_login column...")
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN last_failed_login TIMESTAMP;
        """)
        
        # Add account_locked_until column
        print("Adding account_locked_until column...")
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN account_locked_until TIMESTAMP;
        """)
        
        # Commit the transaction
        conn.commit()
        print("Migration completed successfully.")
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error during migration: {e}")
        sys.exit(1)

if __name__ == "__main__":
    apply_migration()
