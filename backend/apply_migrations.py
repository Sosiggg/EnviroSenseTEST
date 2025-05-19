"""
Combined migration script to apply all database migrations.
This script will:
1. Add brute force protection fields
2. Add password reset fields
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

def apply_brute_force_protection_migration():
    """Apply the brute force protection migration."""
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
        
        # Check if the columns already exist
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'failed_login_attempts';
        """)
        
        if cur.fetchone():
            print("Brute force protection migration already applied.")
            cur.close()
            conn.close()
            return
        
        # Add the new columns
        print("Adding brute force protection columns to users table...")
        
        # Add failed_login_attempts column
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
        """)
        
        # Add last_failed_login column
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN last_failed_login TIMESTAMP;
        """)
        
        # Add account_locked_until column
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN account_locked_until TIMESTAMP;
        """)
        
        # Commit the transaction
        conn.commit()
        print("Brute force protection migration completed successfully.")
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error during brute force protection migration: {e}")
        return False
    
    return True

def apply_password_reset_migration():
    """Apply the password reset migration."""
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
        
        # Check if the columns already exist
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'reset_token';
        """)
        
        if cur.fetchone():
            print("Password reset migration already applied.")
            cur.close()
            conn.close()
            return
        
        # Add the new columns
        print("Adding password reset columns to users table...")
        cur.execute("""
            ALTER TABLE users 
            ADD COLUMN reset_token VARCHAR,
            ADD COLUMN reset_token_expires TIMESTAMP;
        """)
        
        # Commit the transaction
        conn.commit()
        print("Password reset migration completed successfully.")
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error during password reset migration: {e}")
        return False
    
    return True

def apply_all_migrations():
    """Apply all migrations."""
    print("Starting database migrations...")
    
    # Apply brute force protection migration
    if apply_brute_force_protection_migration():
        print("Brute force protection migration successful.")
    else:
        print("Brute force protection migration failed.")
    
    # Apply password reset migration
    if apply_password_reset_migration():
        print("Password reset migration successful.")
    else:
        print("Password reset migration failed.")
    
    print("All migrations completed.")

if __name__ == "__main__":
    apply_all_migrations()
