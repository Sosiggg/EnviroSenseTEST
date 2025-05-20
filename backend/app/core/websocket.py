import json
import logging
import time
import asyncio
from fastapi import WebSocket
from typing import Dict, List, Set, Optional
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {}
        self.connection_count: int = 0
        self.last_cleanup = time.time()
        self.cleanup_interval = 60  # seconds
        self.connection_timestamps: Dict[WebSocket, float] = {}
        self.max_connections_per_user = 5  # Limit connections per user

    async def connect(self, websocket: WebSocket, user_id: int):
        # Check if we need to clean up stale connections
        await self._cleanup_stale_connections()

        # Accept the connection
        await websocket.accept()

        # Initialize user's connection list if needed
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []

        # Check if user has too many connections
        if len(self.active_connections[user_id]) >= self.max_connections_per_user:
            # Remove the oldest connection for this user
            oldest_conn = self.active_connections[user_id][0]
            try:
                await oldest_conn.close(code=1000, reason="Too many connections")
            except Exception:
                pass
            self.active_connections[user_id].pop(0)
            self.connection_count -= 1
            if oldest_conn in self.connection_timestamps:
                del self.connection_timestamps[oldest_conn]
            logger.warning(f"Closed oldest connection for user {user_id} due to connection limit")

        # Add the new connection
        self.active_connections[user_id].append(websocket)
        self.connection_timestamps[websocket] = time.time()
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

                # Remove from timestamps
                if websocket in self.connection_timestamps:
                    del self.connection_timestamps[websocket]

                # Log disconnection
                logger.info(f"WebSocket disconnected: User ID {user_id} | Total connections: {self.connection_count}")

            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def _cleanup_stale_connections(self):
        """Clean up stale connections periodically"""
        current_time = time.time()
        if current_time - self.last_cleanup < self.cleanup_interval:
            return

        self.last_cleanup = current_time
        stale_threshold = current_time - 300  # 5 minutes

        for user_id in list(self.active_connections.keys()):
            for conn in list(self.active_connections[user_id]):
                # Check if connection is stale
                if conn in self.connection_timestamps and self.connection_timestamps[conn] < stale_threshold:
                    try:
                        await conn.close(code=1000, reason="Connection timeout")
                    except Exception:
                        pass
                    self.active_connections[user_id].remove(conn)
                    self.connection_count -= 1
                    del self.connection_timestamps[conn]
                    logger.info(f"Closed stale connection for user {user_id}")

            # Clean up empty user entries
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

        logger.info(f"Connection cleanup completed. Active connections: {self.connection_count}")

    async def send_personal_message(self, message: str, websocket: WebSocket):
        try:
            await websocket.send_text(message)
            # Update the timestamp for this connection
            self.connection_timestamps[websocket] = time.time()
        except Exception as e:
            logger.error(f"Error sending message: {str(e)}")

    async def broadcast(self, message: str, user_id: int):
        if user_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_text(message)
                    # Update the timestamp for this connection
                    self.connection_timestamps[connection] = time.time()
                except Exception as e:
                    logger.error(f"Error broadcasting to user {user_id}: {str(e)}")
                    disconnected.append(connection)

            # Clean up any disconnected websockets
            for conn in disconnected:
                if conn in self.active_connections[user_id]:
                    self.active_connections[user_id].remove(conn)
                    self.connection_count -= 1
                    if conn in self.connection_timestamps:
                        del self.connection_timestamps[conn]

            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def handle_ping(self, websocket: WebSocket):
        """Handle ping messages from clients"""
        try:
            await websocket.send_text(json.dumps({"type": "pong"}))
            # Update the timestamp for this connection
            self.connection_timestamps[websocket] = time.time()
        except Exception as e:
            logger.error(f"Error sending pong: {str(e)}")

# Create a global connection manager instance
manager = ConnectionManager()
