"""
Basic User model that only includes columns that definitely exist in the database.
This is used as a fallback when the full User model can't be used due to missing columns.
"""
from sqlalchemy import Column, Integer, String, Boolean
from app.db.database import Base

class BasicUser(Base):
    __tablename__ = "users"
    __table_args__ = {'extend_existing': True}

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)

    # No relationship with sensor data in the basic model
    # This avoids conflicts with the User model
