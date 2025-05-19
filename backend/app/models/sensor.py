from sqlalchemy import Column, Integer, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.db.database import Base

class SensorData(Base):
    __tablename__ = "sensor_data"

    id = Column(Integer, primary_key=True, index=True)
    temperature = Column(Float)
    humidity = Column(Float)
    obstacle = Column(Boolean)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    user_id = Column(Integer, ForeignKey("users.id"))

    # Relationship with user
    # Use foreign_keys to explicitly specify which column to use
    # This avoids conflicts with BasicUser
    user = relationship("User", back_populates="sensor_data", foreign_keys=[user_id])
