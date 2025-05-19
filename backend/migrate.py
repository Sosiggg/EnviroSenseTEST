"""
Simple migration script to add all required columns to the users table.
This script will be run during the Render deployment.
"""
import os
import sys
import psycopg2
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get database connection details from environment variables
host = os.getenv("POSTGRES_HOST", "dpg-cqvnvvf6fquc73f1iqg0-a.oregon-postgres.render.com")
database = os.getenv("POSTGRES_DB", "envirosense_db")
db_user = os.getenv("POSTGRES_USER", "envirosense_db_user")
db_password = os.getenv("POSTGRES_PASSWORD", "Ij9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9Yd9")
port = os.getenv("POSTGRES_PORT", "5432")

def apply_migration():
    """Apply all migrations to the database."""
    try:
        # Connect to the database
        logger.info(f"Connecting to database {database} on {host}...")
        conn = psycopg2.connect(
            host=host,
            database=database,
            user=db_user,
            password=db_password,
            port=port
        )
        
        # Create a cursor
        cur = conn.cursor()
        
        # Add columns one by one with error handling for each
        columns_to_add = [
            ("failed_login_attempts", "INTEGER DEFAULT 0"),
            ("last_failed_login", "TIMESTAMP"),
            ("account_locked_until", "TIMESTAMP"),
            ("reset_token", "VARCHAR"),
            ("reset_token_expires", "TIMESTAMP")
        ]
        
        for column_name, column_type in columns_to_add:
            try:
                # Check if column exists
                cur.execute(f"""
                    SELECT column_name 
                    FROM information_schema.columns 
                    WHERE table_name = 'users' AND column_name = '{column_name}';
                """)
                
                if cur.fetchone():
                    logger.info(f"Column '{column_name}' already exists.")
                else:
                    # Add column
                    logger.info(f"Adding column '{column_name}' to users table...")
                    cur.execute(f"""
                        ALTER TABLE users 
                        ADD COLUMN {column_name} {column_type};
                    """)
                    conn.commit()
                    logger.info(f"Column '{column_name}' added successfully.")
            except Exception as e:
                logger.error(f"Error adding column '{column_name}': {e}")
                # Continue with next column even if this one fails
                conn.rollback()
        
        # Close the cursor and connection
        cur.close()
        conn.close()
        logger.info("Migration completed.")
        
    except Exception as e:
        logger.error(f"Error during migration: {e}")
        sys.exit(1)

if __name__ == "__main__":
    apply_migration()
