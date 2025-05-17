from sqlalchemy.orm import Session
from app.db.database import Base, engine
from app.models.user import User
from app.models.sensor import SensorData

def create_tables():
    Base.metadata.create_all(bind=engine)
