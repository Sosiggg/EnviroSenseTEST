from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
import os
import logging
from dotenv import load_dotenv

# Configure logging
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Get database URL from environment variables with a default value
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./envirosense.db")

# Use SQLite for local development if PostgreSQL URL is not available
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    # For PostgreSQL on Render with optimized connection pool settings
    try:
        # Use even more conservative connection pool settings to avoid hitting limits
        engine = create_engine(
            DATABASE_URL,
            poolclass=QueuePool,
            pool_size=3,  # Further reduced to avoid hitting connection limits
            max_overflow=5,  # Further reduced to avoid hitting connection limits
            pool_timeout=90,  # Increased timeout to allow for longer queries
            pool_recycle=900,  # Recycle connections after 15 minutes
            pool_pre_ping=True,  # Check connection validity before using it
            connect_args={
                "connect_timeout": 15,  # Increased connection timeout
                "keepalives": 1,  # Enable keepalives
                "keepalives_idle": 60,  # Idle time before sending keepalive
                "keepalives_interval": 10,  # Interval between keepalives
                "keepalives_count": 3  # Number of keepalives before giving up
            }
        )
        logger.info(f"Database engine created with pool_size=3, max_overflow=5, pool_timeout=90, pool_recycle=900")
    except Exception as e:
        logger.error(f"Error creating database engine: {e}")
        # Fallback to minimal settings
        engine = create_engine(
            DATABASE_URL,
            poolclass=QueuePool,
            pool_size=1,  # Absolute minimum
            max_overflow=2,  # Absolute minimum overflow
            pool_timeout=30,
            pool_pre_ping=True
        )
        logger.warning(f"Using fallback database engine settings due to error: {e}")

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()

# Get database session with retry logic
def get_db():
    retries = 5  # Increased retries
    last_exception = None

    for attempt in range(retries):
        try:
            db = SessionLocal()

            # Add a simple test query that doesn't use text() to avoid issues
            if attempt == 0:  # Only test on first attempt to reduce overhead
                try:
                    # Use a simple query with text() to avoid SQLAlchemy errors
                    from sqlalchemy import text
                    db.execute(text("SELECT 1")).fetchone()
                except Exception as test_error:
                    logger.warning(f"Connection test failed: {str(test_error)}")
                    # Don't fail here, continue with the session

            try:
                yield db
            finally:
                try:
                    db.close()
                except Exception as close_error:
                    logger.warning(f"Error closing database connection: {str(close_error)}")
            return  # Successfully yielded and closed the session
        except Exception as e:
            last_exception = e
            logger.warning(f"Database connection attempt {attempt+1}/{retries} failed: {str(e)}")
            # If we have a session, make sure it's closed before retrying
            try:
                if 'db' in locals():
                    db.close()
            except Exception as close_error:
                logger.warning(f"Error closing database connection during retry: {str(close_error)}")

            # Add exponential backoff
            if attempt < retries - 1:  # Don't sleep on the last attempt
                import time
                sleep_time = 0.1 * (2 ** attempt)  # 0.1, 0.2, 0.4, 0.8, 1.6 seconds
                logger.info(f"Waiting {sleep_time:.2f} seconds before retry...")
                time.sleep(sleep_time)

    # If we get here, all retries failed
    logger.error(f"All database connection attempts failed: {str(last_exception)}")
    # Return a default error response instead of raising an exception
    from fastapi import HTTPException, status
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Database connection failed. Please try again later."
    )
