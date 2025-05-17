from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session
import json

from app.core.auth import get_current_active_user, verify_token
from app.core.websocket import manager
from app.db.database import get_db
from app.models.user import User
from app.models.sensor import SensorData
from app.schemas.sensor import SensorData as SensorDataSchema, SensorDataCreate

router = APIRouter()

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str, db: Session = Depends(get_db)):
    # Verify token
    user = verify_token(token, db)
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    
    # Accept connection
    await manager.connect(websocket, user.id)
    
    try:
        while True:
            # Receive JSON data from ESP32
            data = await websocket.receive_text()
            
            try:
                # Parse JSON data
                json_data = json.loads(data)
                
                # Create sensor data object
                sensor_data = SensorDataCreate(
                    temperature=json_data.get("temperature"),
                    humidity=json_data.get("humidity"),
                    obstacle=json_data.get("obstacle")
                )
                
                # Save sensor data to database
                db_sensor_data = SensorData(
                    temperature=sensor_data.temperature,
                    humidity=sensor_data.humidity,
                    obstacle=sensor_data.obstacle,
                    user_id=user.id
                )
                db.add(db_sensor_data)
                db.commit()
                
                # Print sensor data
                print(f"Received sensor data: Temperature={sensor_data.temperature}°C, Humidity={sensor_data.humidity}%, Obstacle={sensor_data.obstacle}")
                
                # Send acknowledgment
                await manager.send_personal_message(
                    json.dumps({"status": "success", "message": "Data received"}),
                    websocket
                )
                
            except json.JSONDecodeError:
                # Handle invalid JSON
                await manager.send_personal_message(
                    json.dumps({"status": "error", "message": "Invalid JSON data"}),
                    websocket
                )
                
    except WebSocketDisconnect:
        # Handle disconnection
        manager.disconnect(websocket, user.id)

@router.get("/data", response_model=list[SensorDataSchema])
async def get_sensor_data(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    sensor_data = db.query(SensorData).filter(SensorData.user_id == current_user.id).all()
    return sensor_data
