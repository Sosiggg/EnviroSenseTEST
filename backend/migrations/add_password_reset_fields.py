"""
Migration script to add password reset fields to the User model.
Run this script to update the database schema.
"""
import os
import sys
import psycopg2
from dotenv import load_dotenv

# Add the parent directory to the path so we can import from app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load environment variables
load_dotenv()

# Get database connection details from environment variables
host = os.getenv("POSTGRES_HOST", "dpg-cqvnvvf6fquc73f1iqg0-a.oregon-postgres.render.com")
database = os.getenv("POSTGRES_DB", "envirosense_db")
db_user = os.getenv("POSTGRES_USER", "envirosense_db_user")
db_password = os.getenv("POSTGRES_PASSWORD", "Ij9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9")
port = os.getenv("POSTGRES_PORT", "5432")

def run_migration():
    """Run the migration to add password reset fields to the User model."""
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
            print("Migration already applied. Columns already exist.")
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
        print("Migration completed successfully.")
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error during migration: {e}")
        sys.exit(1)

if __name__ == "__main__":
    run_migration()
