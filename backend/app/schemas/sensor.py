from pydantic import BaseModel
from datetime import datetime

class SensorDataBase(BaseModel):
    temperature: float
    humidity: float
    obstacle: bool

class SensorDataCreate(SensorDataBase):
    pass

class SensorData(SensorDataBase):
    id: int
    timestamp: datetime
    user_id: int

    class Config:
        from_attributes = True
