from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

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
    # For PostgreSQL on Render
    engine = create_engine(DATABASE_URL)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()

# Get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
