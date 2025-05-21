from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session
from sqlalchemy import text
import json
import logging
import asyncio
from datetime import datetime

from app.core.auth import get_current_active_user, verify_token
from app.core.websocket import manager
from app.core.db_utils import get_user_by_email

# Configure logging
logger = logging.getLogger(__name__)
from app.db.database import get_db
from app.models.sensor import SensorData
from app.schemas.sensor import SensorDataCreate

router = APIRouter()

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, db: Session = Depends(get_db), token: str = None, email: str = None):
    # Initialize user variable
    user = None
    client_host = websocket.client.host if hasattr(websocket, 'client') and hasattr(websocket.client, 'host') else "unknown"

    try:
        # Log connection attempt with client info
        logger.info(f"WebSocket connection attempt from {client_host}")
        logger.info(f"WebSocket connection parameters - token: {'provided' if token else 'not provided'}, email: {email if email else 'not provided'}")

        # Check if we have an email parameter
        if email:
            # Authenticate using email
            logger.info(f"WebSocket connection attempt with email: {email}")
            user = get_user_by_email(db, email)

            if not user:
                logger.warning(f"WebSocket connection rejected: Invalid email '{email}' from {client_host}")
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                return

            # Log successful authentication
            logger.info(f"WebSocket authenticated for user {user.id if hasattr(user, 'id') else user['id']} (email: {email}) from {client_host}")
        elif token:
            # Fallback to token authentication
            logger.info(f"WebSocket connection attempt with token: {token[:10]}... from {client_host}")
            user = verify_token(token, db)

            if not user:
                logger.warning(f"WebSocket connection rejected: Invalid token from {client_host}")
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                return

            # Log successful authentication
            logger.info(f"WebSocket authenticated for user {user.id if hasattr(user, 'id') else user['id']} (username: {user.get('username', 'unknown')}) from {client_host}")
        else:
            # No authentication provided
            logger.warning(f"WebSocket connection rejected: No authentication provided from {client_host}")
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Accept connection through the manager
        await manager.connect(websocket, user['id'])

        # Main message processing loop
        while True:
            # Receive JSON data with timeout handling
            try:
                # Receive data with a timeout
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=300  # 5 minute timeout
                )
            except asyncio.TimeoutError:
                # Handle timeout - send a ping to check if client is still there
                logger.info(f"WebSocket timeout for user {user['id']}, sending ping")
                try:
                    await manager.send_personal_message(
                        json.dumps({"type": "ping", "message": "Connection check"}),
                        websocket
                    )
                    continue
                except Exception:
                    # If ping fails, client is disconnected
                    logger.info(f"Ping failed for user {user['id']}, closing connection")
                    raise WebSocketDisconnect()

            # Process the received data
            try:
                # Parse JSON data
                json_data = json.loads(data)
                logger.debug(f"Received WebSocket message from user {user['id']}: {json_data}")

                # Check if this is a ping message
                if json_data.get("type") == "ping":
                    logger.debug(f"Ping received from user {user['id']}")
                    await manager.handle_ping(websocket)
                    continue

                # Check if we have sensor data
                if "temperature" in json_data:
                    # Create sensor data object with validation
                    try:
                        # Validate and convert data
                        temperature = float(json_data.get("temperature", 0))
                        humidity = float(json_data.get("humidity", 0))
                        obstacle = bool(json_data.get("obstacle", False))

                        # Create sensor data object
                        sensor_data = SensorDataCreate(
                            temperature=temperature,
                            humidity=humidity,
                            obstacle=obstacle
                        )

                        # Log the data being saved
                        logger.info(f"Saving sensor data for user {user['id']}: T={temperature}°C, H={humidity}%, O={obstacle}")

                        try:
                            # Save sensor data to database using raw SQL with error handling
                            query = text("""
                                INSERT INTO sensor_data
                                (temperature, humidity, obstacle, user_id, timestamp)
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

                            logger.info(f"Sensor data saved successfully for user {user['id']}, id={sensor_id}")

                            # Send acknowledgment
                            await manager.send_personal_message(
                                json.dumps({
                                    "status": "success",
                                    "message": "Data received and saved",
                                    "id": sensor_id
                                }),
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

                        except Exception as db_error:
                            # Handle database errors
                            logger.error(f"Database error saving sensor data for user {user['id']}: {db_error}")
                            await manager.send_personal_message(
                                json.dumps({
                                    "status": "error",
                                    "message": "Database error, could not save data"
                                }),
                                websocket
                            )
                            # Try to rollback the transaction
                            try:
                                db.rollback()
                            except:
                                pass

                    except (ValueError, TypeError) as validation_error:
                        # Handle data validation errors
                        logger.warning(f"Invalid sensor data from user {user['id']}: {validation_error}")
                        await manager.send_personal_message(
                            json.dumps({
                                "status": "error",
                                "message": f"Invalid sensor data: {str(validation_error)}"
                            }),
                            websocket
                        )

                else:
                    # Unknown message type
                    logger.warning(f"Unknown message type received from user {user['id']}: {json_data}")
                    await manager.send_personal_message(
                        json.dumps({
                            "status": "error",
                            "message": "Unknown message type"
                        }),
                        websocket
                    )

            except json.JSONDecodeError as json_error:
                # Handle invalid JSON
                logger.warning(f"Invalid JSON received from user {user['id']}: {json_error}")
                await manager.send_personal_message(
                    json.dumps({
                        "status": "error",
                        "message": "Invalid JSON data"
                    }),
                    websocket
                )

            except Exception as processing_error:
                # Handle other errors during message processing
                logger.error(f"Error processing message from user {user['id']}: {processing_error}")
                await manager.send_personal_message(
                    json.dumps({
                        "status": "error",
                        "message": f"Server error: {str(processing_error)}"
                    }),
                    websocket
                )

    except WebSocketDisconnect:
        # Handle normal disconnection
        if user:
            logger.info(f"WebSocket disconnected normally for user {user['id']}")
            manager.disconnect(websocket, user['id'])
        else:
            logger.info("WebSocket disconnected before authentication")

    except Exception as connection_error:
        # Handle unexpected errors
        if user:
            logger.error(f"Unexpected error in WebSocket connection for user {user['id']}: {connection_error}")
            manager.disconnect(websocket, user['id'])
        else:
            logger.error(f"Unexpected error in WebSocket connection before authentication: {connection_error}")

    finally:
        # Ensure connection is properly cleaned up
        if user:
            try:
                manager.disconnect(websocket, user['id'])
                logger.info(f"WebSocket cleanup completed for user {user['id']}")
            except Exception as cleanup_error:
                logger.error(f"Error during WebSocket cleanup for user {user['id']}: {cleanup_error}")

        # Try to close the websocket if it's still open
        try:
            await websocket.close()
        except:
            pass

@router.options("/data", status_code=status.HTTP_200_OK)
async def sensor_data_options():
    """
    Handle OPTIONS requests for the sensor data endpoint.
    This is needed for CORS preflight requests.
    """
    from fastapi.responses import JSONResponse

    # Return a response with CORS headers
    return JSONResponse(
        content={},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
            "Access-Control-Max-Age": "86400",  # Cache preflight requests for 24 hours
        }
    )

@router.get("/data")
async def get_sensor_data(
    current_user: dict = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    start_date: str = None,
    end_date: str = None,
    page: int = 1,
    page_size: int = 10
):
    try:
        # Log the request with query parameters
        logger.info(f"Getting sensor data for user {current_user['id']} with params: start_date={start_date}, end_date={end_date}, page={page}, page_size={page_size}")

        # Validate and parse date parameters if provided
        date_filter_clause = ""
        query_params = {"user_id": current_user['id']}

        if start_date and end_date:
            try:
                # Parse ISO format dates
                logger.info(f"Filtering by date range: {start_date} to {end_date}")

                # Check if the date is in the future
                try:
                    start_date_obj = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                    end_date_obj = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                    now = datetime.now()

                    # If both dates are in the future, return empty results immediately
                    if start_date_obj > now and end_date_obj > now:
                        logger.info(f"Both dates are in the future, returning empty results")
                        return {
                            "data": [],
                            "pagination": {
                                "page": page,
                                "page_size": page_size,
                                "total_count": 0,
                                "total_pages": 0,
                                "has_next": False,
                                "has_prev": False
                            }
                        }
                except Exception as future_check_error:
                    logger.error(f"Error checking future dates: {future_check_error}")

                date_filter_clause = "AND timestamp BETWEEN :start_date AND :end_date"
                query_params["start_date"] = start_date
                query_params["end_date"] = end_date
            except Exception as date_error:
                logger.error(f"Error parsing date parameters: {date_error}")
                # Continue without date filtering if there's an error

        # Calculate pagination
        offset = (page - 1) * page_size

        try:
            # First, get total count for pagination info
            count_query = text(f"""
                SELECT COUNT(*)
                FROM sensor_data
                WHERE user_id = :user_id {date_filter_clause}
            """)

            total_count = db.execute(count_query, query_params).scalar() or 0
            logger.info(f"Total matching records: {total_count}")

            # Use raw SQL to get sensor data with pagination and date filtering
            query = text(f"""
                SELECT id, temperature, humidity, obstacle, user_id, timestamp
                FROM sensor_data
                WHERE user_id = :user_id {date_filter_clause}
                ORDER BY timestamp DESC
                LIMIT :limit OFFSET :offset
            """)

            # Add pagination parameters
            query_params["limit"] = page_size
            query_params["offset"] = offset

            # Execute with error handling
            try:
                logger.debug(f"Executing query with params: {query_params}")
                result = db.execute(query, query_params)
            except Exception as db_error:
                logger.error(f"Database error in get_sensor_data: {db_error}")
                # Try a simpler query as fallback without date filtering
                fallback_query = text("""
                    SELECT * FROM sensor_data
                    WHERE user_id = :user_id
                    ORDER BY timestamp DESC
                    LIMIT :limit OFFSET :offset
                """)
                fallback_params = {"user_id": current_user['id'], "limit": page_size, "offset": offset}
                logger.info(f"Trying fallback query: {fallback_query}")
                result = db.execute(fallback_query, fallback_params)

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

            # Calculate pagination metadata
            total_pages = (total_count + page_size - 1) // page_size  # Ceiling division
            has_next = page < total_pages
            has_prev = page > 1

            logger.info(f"Successfully retrieved {len(sensor_data)} sensor data points for user {current_user['id']} (page {page}/{total_pages})")

            # Return data with pagination metadata and CORS headers
            from fastapi.responses import JSONResponse
            return JSONResponse(
                content={
                    "data": sensor_data,
                    "pagination": {
                        "page": page,
                        "page_size": page_size,
                        "total_count": total_count,
                        "total_pages": total_pages,
                        "has_next": has_next,
                        "has_prev": has_prev
                    }
                },
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
                }
            )

        except Exception as inner_error:
            logger.error(f"Inner error in get_sensor_data: {inner_error}")
            # Try a different approach - use ORM with pagination
            try:
                query = db.query(SensorData).filter(SensorData.user_id == current_user['id'])

                # Apply date filtering if provided
                if start_date and end_date:
                    query = query.filter(SensorData.timestamp.between(start_date, end_date))

                # Get total count for pagination
                total_count = query.count()

                # Apply pagination and ordering
                sensor_data_list = query.order_by(SensorData.timestamp.desc()) \
                    .offset(offset).limit(page_size).all()

                # Convert to list of dictionaries
                data = [
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

                # Calculate pagination metadata
                total_pages = (total_count + page_size - 1) // page_size
                has_next = page < total_pages
                has_prev = page > 1

                from fastapi.responses import JSONResponse
                return JSONResponse(
                    content={
                        "data": data,
                        "pagination": {
                            "page": page,
                            "page_size": page_size,
                            "total_count": total_count,
                            "total_pages": total_pages,
                            "has_next": has_next,
                            "has_prev": has_prev
                        }
                    },
                    headers={
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET, OPTIONS",
                        "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
                    }
                )
            except Exception as orm_error:
                logger.error(f"ORM approach failed: {orm_error}")
                raise orm_error

    except Exception as e:
        logger.error(f"Error getting sensor data: {e}")
        # Return an empty result with pagination structure and CORS headers
        from fastapi.responses import JSONResponse
        return JSONResponse(
            content={
                "data": [],
                "pagination": {
                    "page": page,
                    "page_size": page_size,
                    "total_count": 0,
                    "total_pages": 0,
                    "has_next": False,
                    "has_prev": False
                }
            },
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
            }
        )

@router.options("/data/latest", status_code=status.HTTP_200_OK)
async def latest_sensor_data_options():
    """
    Handle OPTIONS requests for the latest sensor data endpoint.
    This is needed for CORS preflight requests.
    """
    from fastapi.responses import JSONResponse

    # Return a response with CORS headers
    return JSONResponse(
        content={},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
            "Access-Control-Max-Age": "86400",  # Cache preflight requests for 24 hours
        }
    )

@router.get("/data/latest")
async def get_latest_sensor_data(current_user: dict = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Get the latest sensor data for the current user"""
    try:
        # Log the request with more details
        logger.info(f"Getting latest sensor data for user {current_user['id']} (username: {current_user.get('username', 'unknown')})")

        # First, check if the user has any sensor data at all
        try:
            # Use a simple count query first to check if data exists
            count_query = text("SELECT COUNT(*) FROM sensor_data WHERE user_id = :user_id")
            count_result = db.execute(count_query, {"user_id": current_user['id']}).scalar()

            logger.info(f"User {current_user['id']} has {count_result} sensor data records")

            if count_result == 0:
                logger.info(f"No sensor data found for user {current_user['id']}")
                # Return empty data instead of 404 error
                return {
                    "id": 0,
                    "temperature": 0.0,
                    "humidity": 0.0,
                    "obstacle": False,
                    "user_id": current_user['id'],
                    "timestamp": datetime.now().isoformat(),
                    "message": "No sensor data available yet"
                }

            # Use raw SQL to get latest sensor data with explicit column selection
            query = text("""
                SELECT
                    id,
                    temperature,
                    humidity,
                    obstacle,
                    user_id,
                    timestamp
                FROM sensor_data
                WHERE user_id = :user_id
                ORDER BY timestamp DESC
                LIMIT 1
            """)

            # Execute with detailed error handling
            try:
                logger.debug(f"Executing query for user {current_user['id']}")
                result = db.execute(query, {"user_id": current_user['id']})
                row = result.fetchone()
                logger.debug(f"Query executed successfully, row: {row is not None}")
            except Exception as db_error:
                logger.error(f"Database error in get_latest_sensor_data: {db_error}")
                # Try a simpler query as fallback
                fallback_query = text("SELECT * FROM sensor_data WHERE user_id = :user_id ORDER BY timestamp DESC LIMIT 1")
                logger.info(f"Trying fallback query for user {current_user['id']}")
                result = db.execute(fallback_query, {"user_id": current_user['id']})
                row = result.fetchone()
                logger.debug(f"Fallback query executed, row: {row is not None}")

            if not row:
                logger.warning(f"No rows returned for user {current_user['id']} despite count > 0")
                # Return empty data instead of 404 error
                return {
                    "id": 0,
                    "temperature": 0.0,
                    "humidity": 0.0,
                    "obstacle": False,
                    "user_id": current_user['id'],
                    "timestamp": datetime.now().isoformat(),
                    "message": "No sensor data available yet"
                }

            # Convert to dictionary with robust error handling for each field
            latest_data = {
                "id": 0,
                "temperature": 0.0,
                "humidity": 0.0,
                "obstacle": False,
                "user_id": current_user['id'],
                "timestamp": datetime.now().isoformat()
            }

            # Log the raw row data for debugging
            logger.debug(f"Raw row data: {row}")

            # Process each field individually with detailed error handling
            try:
                # Process ID
                try:
                    latest_data["id"] = int(row[0]) if row[0] is not None else 0
                except (TypeError, ValueError) as e:
                    logger.warning(f"Error converting ID: {e}, value: {row[0]}")
                    latest_data["id"] = 0

                # Process temperature
                try:
                    latest_data["temperature"] = float(row[1]) if row[1] is not None else 0.0
                except (TypeError, ValueError) as e:
                    logger.warning(f"Error converting temperature: {e}, value: {row[1]}")
                    latest_data["temperature"] = 0.0

                # Process humidity
                try:
                    latest_data["humidity"] = float(row[2]) if row[2] is not None else 0.0
                except (TypeError, ValueError) as e:
                    logger.warning(f"Error converting humidity: {e}, value: {row[2]}")
                    latest_data["humidity"] = 0.0

                # Process obstacle
                try:
                    latest_data["obstacle"] = bool(row[3]) if row[3] is not None else False
                except (TypeError, ValueError) as e:
                    logger.warning(f"Error converting obstacle: {e}, value: {row[3]}")
                    latest_data["obstacle"] = False

                # Process user_id
                try:
                    latest_data["user_id"] = int(row[4]) if row[4] is not None else current_user['id']
                except (TypeError, ValueError) as e:
                    logger.warning(f"Error converting user_id: {e}, value: {row[4]}")
                    latest_data["user_id"] = current_user['id']

                # Process timestamp with extra care
                try:
                    if row[5] is not None:
                        try:
                            latest_data["timestamp"] = row[5].isoformat()
                        except AttributeError:
                            # If timestamp is not a datetime object
                            latest_data["timestamp"] = str(row[5])
                    else:
                        latest_data["timestamp"] = datetime.now().isoformat()
                except Exception as e:
                    logger.warning(f"Error processing timestamp: {e}, value: {row[5]}")
                    latest_data["timestamp"] = datetime.now().isoformat()

            except Exception as conversion_error:
                logger.error(f"Error converting sensor data: {conversion_error}, row: {row}")
                # We'll continue with the default values already set in latest_data

            logger.info(f"Successfully retrieved latest sensor data for user {current_user['id']}")
            from fastapi.responses import JSONResponse
            return JSONResponse(
                content=latest_data,
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
                }
            )

        except Exception as inner_error:
            logger.error(f"Inner error in get_latest_sensor_data: {inner_error}")
            # Try a different approach - use ORM with explicit error handling
            try:
                logger.info(f"Trying ORM approach for user {current_user['id']}")
                sensor_data = db.query(SensorData).filter(
                    SensorData.user_id == current_user['id']
                ).order_by(SensorData.timestamp.desc()).first()

                if not sensor_data:
                    logger.info(f"No sensor data found using ORM for user {current_user['id']}")
                    # Return empty data instead of 404 error with CORS headers
                    from fastapi.responses import JSONResponse
                    return JSONResponse(
                        content={
                            "id": 0,
                            "temperature": 0.0,
                            "humidity": 0.0,
                            "obstacle": False,
                            "user_id": current_user['id'],
                            "timestamp": datetime.now().isoformat(),
                            "message": "No sensor data available yet"
                        },
                        headers={
                            "Access-Control-Allow-Origin": "*",
                            "Access-Control-Allow-Methods": "GET, OPTIONS",
                            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
                        }
                    )

                # Convert to dictionary with error handling
                result_data = {
                    "id": 0,
                    "temperature": 0.0,
                    "humidity": 0.0,
                    "obstacle": False,
                    "user_id": current_user['id'],
                    "timestamp": datetime.now().isoformat()
                }

                # Process each field individually
                try:
                    result_data["id"] = sensor_data.id
                except Exception as e:
                    logger.warning(f"Error getting id from ORM: {e}")

                try:
                    result_data["temperature"] = float(sensor_data.temperature) if sensor_data.temperature is not None else 0.0
                except Exception as e:
                    logger.warning(f"Error getting temperature from ORM: {e}")

                try:
                    result_data["humidity"] = float(sensor_data.humidity) if sensor_data.humidity is not None else 0.0
                except Exception as e:
                    logger.warning(f"Error getting humidity from ORM: {e}")

                try:
                    result_data["obstacle"] = bool(sensor_data.obstacle) if sensor_data.obstacle is not None else False
                except Exception as e:
                    logger.warning(f"Error getting obstacle from ORM: {e}")

                try:
                    result_data["user_id"] = int(sensor_data.user_id) if sensor_data.user_id is not None else current_user['id']
                except Exception as e:
                    logger.warning(f"Error getting user_id from ORM: {e}")

                try:
                    result_data["timestamp"] = sensor_data.timestamp.isoformat() if sensor_data.timestamp else datetime.now().isoformat()
                except Exception as e:
                    logger.warning(f"Error getting timestamp from ORM: {e}")

                logger.info(f"Successfully retrieved latest sensor data using ORM for user {current_user['id']}")
                from fastapi.responses import JSONResponse
                return JSONResponse(
                    content=result_data,
                    headers={
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET, OPTIONS",
                        "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
                    }
                )

            except Exception as orm_error:
                logger.error(f"ORM approach failed: {orm_error}")
                # Fall through to the default response
                raise orm_error

    except HTTPException as http_exc:
        # Return HTTP exceptions with CORS headers
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=http_exc.status_code,
            content={"detail": http_exc.detail},
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
            }
        )
    except Exception as e:
        logger.error(f"Error getting latest sensor data: {e}")
        # Return a default response instead of an error with CORS headers
        from fastapi.responses import JSONResponse
        return JSONResponse(
            content={
                "id": 0,
                "temperature": 0.0,
                "humidity": 0.0,
                "obstacle": False,
                "user_id": current_user['id'],
                "timestamp": datetime.now().isoformat(),
                "message": "Could not retrieve sensor data due to server error"
            },
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
            }
        )

@router.get("/data/check")
async def check_sensor_data(current_user: dict = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Check if the user has any sensor data and return diagnostic information"""
    try:
        # Check if the user has any sensor data at all
        count_query = text("SELECT COUNT(*) FROM sensor_data WHERE user_id = :user_id")
        count_result = db.execute(count_query, {"user_id": current_user['id']}).scalar() or 0

        # Get the date range of available data
        date_range_query = text("""
            SELECT
                MIN(DATE(timestamp)) as first_date,
                MAX(DATE(timestamp)) as last_date
            FROM sensor_data
            WHERE user_id = :user_id
        """)
        date_range_result = db.execute(date_range_query, {"user_id": current_user['id']}).fetchone()

        first_date = date_range_result[0] if date_range_result and date_range_result[0] else None
        last_date = date_range_result[1] if date_range_result and date_range_result[1] else None

        # Get count by date for the last 7 days
        daily_counts_query = text("""
            SELECT
                DATE(timestamp) as date,
                COUNT(*) as count
            FROM sensor_data
            WHERE
                user_id = :user_id
                AND timestamp >= DATE('now', '-7 days')
            GROUP BY DATE(timestamp)
            ORDER BY date DESC
        """)
        daily_counts_result = db.execute(daily_counts_query, {"user_id": current_user['id']}).fetchall()

        daily_counts = [
            {"date": str(row[0]), "count": row[1]}
            for row in daily_counts_result
        ] if daily_counts_result else []

        # Return diagnostic information
        return {
            "total_records": count_result,
            "has_data": count_result > 0,
            "first_date": str(first_date) if first_date else None,
            "last_date": str(last_date) if last_date else None,
            "daily_counts": daily_counts,
            "user_id": current_user['id'],
            "username": current_user.get('username', 'unknown')
        }
    except Exception as e:
        logger.error(f"Error checking sensor data: {e}")
        return {
            "error": True,
            "message": f"Error checking sensor data: {str(e)}",
            "has_data": False,
            "total_records": 0
        }
