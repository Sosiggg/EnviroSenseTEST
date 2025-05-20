from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session
from sqlalchemy import text
import json
import logging
from datetime import datetime

from app.core.auth import get_current_active_user, verify_token
from app.core.websocket import manager

# Configure logging
logger = logging.getLogger(__name__)
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
        logger.warning(f"WebSocket connection attempt with invalid token")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # Accept connection
    await manager.connect(websocket, user['id'])

    try:
        while True:
            # Receive JSON data from ESP32
            data = await websocket.receive_text()

            try:
                # Parse JSON data
                json_data = json.loads(data)

                # Check if this is a ping message
                if json_data.get("type") == "ping":
                    logger.debug(f"Ping received from user {user['id']}")
                    await manager.handle_ping(websocket)
                    continue

                # Check if we have sensor data
                if "temperature" in json_data:
                    # Create sensor data object
                    sensor_data = SensorDataCreate(
                        temperature=json_data.get("temperature"),
                        humidity=json_data.get("humidity"),
                        obstacle=json_data.get("obstacle")
                    )

                    # Save sensor data to database using raw SQL
                    query = text("""
                        INSERT INTO sensor_data (temperature, humidity, obstacle, user_id, timestamp)
                        VALUES (:temperature, :humidity, :obstacle, :user_id, NOW())
                        RETURNING id, timestamp
                    """)

                    result = db.execute(query, {
                        "temperature": sensor_data.temperature,
                        "humidity": sensor_data.humidity,
                        "obstacle": sensor_data.obstacle,
                        "user_id": user['id']
                    })

                    # Get the inserted row's id and timestamp
                    row = result.fetchone()
                    db.commit()

                    sensor_id = row[0]
                    timestamp = row[1]

                    # Log sensor data
                    logger.info(f"Received sensor data from user {user['id']}: Temperature={sensor_data.temperature}°C, Humidity={sensor_data.humidity}%, Obstacle={sensor_data.obstacle}")

                    # Send acknowledgment
                    await manager.send_personal_message(
                        json.dumps({"status": "success", "message": "Data received"}),
                        websocket
                    )

                    # Broadcast to all connections for this user
                    await manager.broadcast(
                        json.dumps({
                            "temperature": sensor_data.temperature,
                            "humidity": sensor_data.humidity,
                            "obstacle": sensor_data.obstacle,
                            "timestamp": timestamp.isoformat(),
                            "id": sensor_id,
                            "user_id": user['id']
                        }),
                        user['id']
                    )
                else:
                    # Unknown message type
                    logger.warning(f"Unknown message type received from user {user['id']}: {json_data}")
                    await manager.send_personal_message(
                        json.dumps({"status": "error", "message": "Unknown message type"}),
                        websocket
                    )

            except json.JSONDecodeError:
                # Handle invalid JSON
                logger.warning(f"Invalid JSON received from user {user['id']}")
                await manager.send_personal_message(
                    json.dumps({"status": "error", "message": "Invalid JSON data"}),
                    websocket
                )
            except Exception as e:
                # Handle other errors
                logger.error(f"Error processing message from user {user['id']}: {str(e)}")
                await manager.send_personal_message(
                    json.dumps({"status": "error", "message": f"Server error: {str(e)}"}),
                    websocket
                )

    except WebSocketDisconnect:
        # Handle disconnection
        logger.info(f"WebSocket disconnected for user {user['id']}")
        manager.disconnect(websocket, user['id'])
    except Exception as e:
        # Handle unexpected errors
        logger.error(f"Unexpected error in WebSocket connection for user {user['id']}: {str(e)}")
        manager.disconnect(websocket, user['id'])

@router.get("/data")
async def get_sensor_data(current_user: dict = Depends(get_current_active_user), db: Session = Depends(get_db)):
    try:
        # Use raw SQL to get sensor data
        query = text("""
            SELECT id, temperature, humidity, obstacle, user_id, timestamp
            FROM sensor_data
            WHERE user_id = :user_id
            ORDER BY timestamp DESC
        """)

        result = db.execute(query, {"user_id": current_user['id']})

        # Convert to list of dictionaries
        sensor_data = []
        for row in result:
            sensor_data.append({
                "id": row[0],
                "temperature": row[1],
                "humidity": row[2],
                "obstacle": row[3],
                "user_id": row[4],
                "timestamp": row[5].isoformat()
            })

        return sensor_data
    except Exception as e:
        logger.error(f"Error getting sensor data: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while getting sensor data: {str(e)}"
        )

@router.get("/data/latest")
async def get_latest_sensor_data(current_user: dict = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Get the latest sensor data for the current user"""
    try:
        # Use raw SQL to get latest sensor data
        query = text("""
            SELECT id, temperature, humidity, obstacle, user_id, timestamp
            FROM sensor_data
            WHERE user_id = :user_id
            ORDER BY timestamp DESC
            LIMIT 1
        """)

        result = db.execute(query, {"user_id": current_user['id']})
        row = result.fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No sensor data found for this user"
            )

        # Convert to dictionary
        latest_data = {
            "id": row[0],
            "temperature": row[1],
            "humidity": row[2],
            "obstacle": row[3],
            "user_id": row[4],
            "timestamp": row[5].isoformat()
        }

        return latest_data
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting latest sensor data: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while getting latest sensor data: {str(e)}"
        )
