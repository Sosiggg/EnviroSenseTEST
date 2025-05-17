from sqlalchemy import Column, Integer, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class SensorData(Base):
    __tablename__ = "sensor_data"

    id = Column(Integer, primary_key=True, index=True)
    temperature = Column(Float)
    humidity = Column(Float)
    obstacle = Column(Boolean)
    timestamp = Column(DateTime, default=datetime.utcnow)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Relationship with user
    user = relationship("User", back_populates="sensor_data")
