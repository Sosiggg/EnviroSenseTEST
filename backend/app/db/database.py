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
    engine = create_engine(
        DATABASE_URL,
        poolclass=QueuePool,
        pool_size=10,  # Increased from default 5
        max_overflow=20,  # Increased from default 10
        pool_timeout=60,  # Increased from default 30
        pool_recycle=1800,  # Recycle connections after 30 minutes
        pool_pre_ping=True  # Check connection validity before using it
    )
    logger.info(f"Database engine created with pool_size=10, max_overflow=20, pool_timeout=60")

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()

# Get database session with retry logic
def get_db():
    retries = 3
    last_exception = None

    for attempt in range(retries):
        try:
            db = SessionLocal()
            # Test the connection with a simple query
            db.execute("SELECT 1")

            try:
                yield db
            finally:
                db.close()
            return  # Successfully yielded and closed the session
        except Exception as e:
            last_exception = e
            logger.warning(f"Database connection attempt {attempt+1}/{retries} failed: {str(e)}")
            # If we have a session, make sure it's closed before retrying
            try:
                if 'db' in locals():
                    db.close()
            except:
                pass

    # If we get here, all retries failed
    logger.error(f"All database connection attempts failed: {str(last_exception)}")
    # Raise the last exception to be handled by FastAPI
    raise last_exception
