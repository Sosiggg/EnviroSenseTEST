import json
import logging
from fastapi import WebSocket
from typing import Dict, List, Set

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {}
        self.connection_count: int = 0

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        self.connection_count += 1

        # Log connection
        logger.info(f"WebSocket connected: User ID {user_id} | Total connections: {self.connection_count}")

        # Send welcome message
        await self.send_personal_message(
            json.dumps({
                "status": "connected",
                "message": "Connected to EnviroSense WebSocket server",
                "connections": self.connection_count
            }),
            websocket
        )

    def disconnect(self, websocket: WebSocket, user_id: int):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
                self.connection_count -= 1

                # Log disconnection
                logger.info(f"WebSocket disconnected: User ID {user_id} | Total connections: {self.connection_count}")

            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_personal_message(self, message: str, websocket: WebSocket):
        try:
            await websocket.send_text(message)
        except Exception as e:
            logger.error(f"Error sending message: {str(e)}")

    async def broadcast(self, message: str, user_id: int):
        if user_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_text(message)
                except Exception as e:
                    logger.error(f"Error broadcasting to user {user_id}: {str(e)}")
                    disconnected.append(connection)

            # Clean up any disconnected websockets
            for conn in disconnected:
                if conn in self.active_connections[user_id]:
                    self.active_connections[user_id].remove(conn)
                    self.connection_count -= 1

            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def handle_ping(self, websocket: WebSocket):
        """Handle ping messages from clients"""
        try:
            await websocket.send_text(json.dumps({"type": "pong"}))
        except Exception as e:
            logger.error(f"Error sending pong: {str(e)}")

# Create a global connection manager instance
manager = ConnectionManager()
