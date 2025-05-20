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
                    query = text("INSERT INTO sensor_data (temperature, humidity, obstacle, user_id, timestamp) VALUES (:temperature, :humidity, :obstacle, :user_id, NOW()) RETURNING id, timestamp")

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
        # Log the request
        logger.info(f"Getting sensor data for user {current_user['id']}")

        try:
            # Use raw SQL to get sensor data
            query = text("SELECT id, temperature, humidity, obstacle, user_id, timestamp FROM sensor_data WHERE user_id = :user_id ORDER BY timestamp DESC")

            # Execute with error handling
            try:
                result = db.execute(query, {"user_id": current_user['id']})
            except Exception as db_error:
                logger.error(f"Database error in get_sensor_data: {db_error}")
                # Try a simpler query as fallback
                fallback_query = text("SELECT * FROM sensor_data WHERE user_id = :user_id ORDER BY timestamp DESC")
                result = db.execute(fallback_query, {"user_id": current_user['id']})

            # Convert to list of dictionaries with error handling
            sensor_data = []
            for row in result:
                try:
                    data_point = {}
                    data_point["id"] = row[0] if row[0] is not None else 0
                    data_point["temperature"] = float(row[1]) if row[1] is not None else 0.0
                    data_point["humidity"] = float(row[2]) if row[2] is not None else 0.0
                    data_point["obstacle"] = bool(row[3]) if row[3] is not None else False
                    data_point["user_id"] = int(row[4]) if row[4] is not None else 0

                    # Handle timestamp with extra care
                    if row[5] is not None:
                        try:
                            data_point["timestamp"] = row[5].isoformat()
                        except AttributeError:
                            # If timestamp is not a datetime object
                            data_point["timestamp"] = str(row[5])
                    else:
                        data_point["timestamp"] = datetime.now().isoformat()

                    sensor_data.append(data_point)
                except Exception as conversion_error:
                    logger.error(f"Error converting sensor data row: {conversion_error}")
                    # Skip this row and continue with the next one
                    continue

            logger.info(f"Successfully retrieved {len(sensor_data)} sensor data points for user {current_user['id']}")
            return sensor_data

        except Exception as inner_error:
            logger.error(f"Inner error in get_sensor_data: {inner_error}")
            # Try a different approach - use ORM
            sensor_data_list = db.query(SensorData).filter(
                SensorData.user_id == current_user['id']
            ).order_by(SensorData.timestamp.desc()).all()

            # Convert to list of dictionaries
            return [
                {
                    "id": data.id,
                    "temperature": data.temperature,
                    "humidity": data.humidity,
                    "obstacle": data.obstacle,
                    "user_id": data.user_id,
                    "timestamp": data.timestamp.isoformat() if data.timestamp else datetime.now().isoformat()
                }
                for data in sensor_data_list
            ]

    except Exception as e:
        logger.error(f"Error getting sensor data: {e}")
        # Return an empty list instead of an error
        return []

@router.get("/data/latest")
async def get_latest_sensor_data(current_user: dict = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Get the latest sensor data for the current user"""
    try:
        # Log the request
        logger.info(f"Getting latest sensor data for user {current_user['id']}")

        try:
            # Use raw SQL to get latest sensor data
            query = text("SELECT id, temperature, humidity, obstacle, user_id, timestamp FROM sensor_data WHERE user_id = :user_id ORDER BY timestamp DESC LIMIT 1")

            # Execute with error handling
            try:
                result = db.execute(query, {"user_id": current_user['id']})
                row = result.fetchone()
            except Exception as db_error:
                logger.error(f"Database error in get_latest_sensor_data: {db_error}")
                # Try a simpler query as fallback
                fallback_query = text("SELECT * FROM sensor_data WHERE user_id = :user_id ORDER BY timestamp DESC LIMIT 1")
                result = db.execute(fallback_query, {"user_id": current_user['id']})
                row = result.fetchone()

            if not row:
                logger.info(f"No sensor data found for user {current_user['id']}")
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No sensor data found for this user"
                )

            # Convert to dictionary with error handling for each field
            latest_data = {}
            try:
                latest_data["id"] = row[0] if row[0] is not None else 0
                latest_data["temperature"] = float(row[1]) if row[1] is not None else 0.0
                latest_data["humidity"] = float(row[2]) if row[2] is not None else 0.0
                latest_data["obstacle"] = bool(row[3]) if row[3] is not None else False
                latest_data["user_id"] = int(row[4]) if row[4] is not None else 0

                # Handle timestamp with extra care
                if row[5] is not None:
                    try:
                        latest_data["timestamp"] = row[5].isoformat()
                    except AttributeError:
                        # If timestamp is not a datetime object
                        latest_data["timestamp"] = str(row[5])
                else:
                    latest_data["timestamp"] = datetime.now().isoformat()
            except Exception as conversion_error:
                logger.error(f"Error converting sensor data: {conversion_error}")
                # If conversion fails, try to extract data more carefully
                for i, column in enumerate(["id", "temperature", "humidity", "obstacle", "user_id", "timestamp"]):
                    try:
                        if i == 5 and row[i] is not None:  # timestamp
                            latest_data[column] = str(row[i])
                        else:
                            latest_data[column] = row[i]
                    except:
                        latest_data[column] = None

            logger.info(f"Successfully retrieved latest sensor data for user {current_user['id']}")
            return latest_data

        except Exception as inner_error:
            logger.error(f"Inner error in get_latest_sensor_data: {inner_error}")
            # Try a different approach - use ORM
            sensor_data = db.query(SensorData).filter(
                SensorData.user_id == current_user['id']
            ).order_by(SensorData.timestamp.desc()).first()

            if not sensor_data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No sensor data found for this user"
                )

            # Convert to dictionary
            return {
                "id": sensor_data.id,
                "temperature": sensor_data.temperature,
                "humidity": sensor_data.humidity,
                "obstacle": sensor_data.obstacle,
                "user_id": sensor_data.user_id,
                "timestamp": sensor_data.timestamp.isoformat() if sensor_data.timestamp else datetime.now().isoformat()
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting latest sensor data: {e}")
        # Return a default response instead of an error
        return {
            "id": 0,
            "temperature": 0.0,
            "humidity": 0.0,
            "obstacle": False,
            "user_id": current_user['id'],
            "timestamp": datetime.now().isoformat(),
            "error": "Could not retrieve sensor data"
        }
