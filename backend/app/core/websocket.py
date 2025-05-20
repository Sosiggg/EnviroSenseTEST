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

        # Log existing connections for this user
        logger.info(f"User {user_id} has {len(self.active_connections[user_id])} existing connections before adding new one")

        # Check if user has too many connections
        if len(self.active_connections[user_id]) >= self.max_connections_per_user:
            # Remove the oldest connection for this user
            oldest_conn = self.active_connections[user_id][0]
            try:
                logger.info(f"Closing oldest connection for user {user_id} due to connection limit")
                await oldest_conn.close(code=1000, reason="Too many connections")
            except Exception as e:
                logger.warning(f"Error closing oldest connection: {e}")

            self.active_connections[user_id].pop(0)
            self.connection_count -= 1
            if oldest_conn in self.connection_timestamps:
                del self.connection_timestamps[oldest_conn]
            logger.warning(f"Closed oldest connection for user {user_id} due to connection limit")

        # Check for any stale connections for this user and close them
        current_time = time.time()
        stale_threshold = current_time - 300  # 5 minutes

        stale_connections = []
        for conn in self.active_connections[user_id]:
            if conn in self.connection_timestamps and self.connection_timestamps[conn] < stale_threshold:
                stale_connections.append(conn)

        # Close stale connections
        for stale_conn in stale_connections:
            try:
                logger.info(f"Closing stale connection for user {user_id}")
                await stale_conn.close(code=1000, reason="Connection timeout")
            except Exception as e:
                logger.warning(f"Error closing stale connection: {e}")

            self.active_connections[user_id].remove(stale_conn)
            self.connection_count -= 1
            if stale_conn in self.connection_timestamps:
                del self.connection_timestamps[stale_conn]

        if stale_connections:
            logger.info(f"Closed {len(stale_connections)} stale connections for user {user_id}")

        # Add the new connection
        self.active_connections[user_id].append(websocket)
        self.connection_timestamps[websocket] = time.time()
        self.connection_count += 1

        # Log connection
        logger.info(f"WebSocket connected: User ID {user_id} | Total connections: {self.connection_count} | User connections: {len(self.active_connections[user_id])}")

        # Send welcome message
        await self.send_personal_message(
            json.dumps({
                "status": "connected",
                "message": "Connected to EnviroSense WebSocket server",
                "connections": self.connection_count,
                "user_connections": len(self.active_connections[user_id]),
                "user_id": user_id
            }),
            websocket
        )

    def disconnect(self, websocket: WebSocket, user_id: int):
        """Disconnect a WebSocket connection and clean up resources"""
        try:
            # Log the disconnect attempt
            logger.info(f"Disconnecting WebSocket for user {user_id}")

            if user_id in self.active_connections:
                # Check if this specific websocket is in the user's connections
                if websocket in self.active_connections[user_id]:
                    # Remove the connection
                    self.active_connections[user_id].remove(websocket)
                    self.connection_count -= 1

                    # Remove from timestamps
                    if websocket in self.connection_timestamps:
                        del self.connection_timestamps[websocket]

                    # Log disconnection
                    logger.info(f"WebSocket disconnected: User ID {user_id} | Total connections: {self.connection_count} | User connections: {len(self.active_connections[user_id])}")
                else:
                    logger.warning(f"WebSocket not found in user {user_id}'s connections during disconnect")

                # If this was the last connection for this user, clean up the user entry
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
                    logger.info(f"Removed user {user_id} from active connections (no more connections)")
            else:
                logger.warning(f"User {user_id} not found in active connections during disconnect")

            # Try to close the websocket if it's not already closed
            try:
                # This is an async operation but we're in a sync method, so we can't await it
                # We'll just try to close it and ignore any errors
                websocket.close()
            except Exception as e:
                logger.debug(f"Error closing websocket during disconnect: {e}")

        except Exception as e:
            # Catch any errors during disconnect to prevent crashes
            logger.error(f"Error during WebSocket disconnect for user {user_id}: {e}")

        # Final check - make sure the connection is removed from timestamps even if other steps failed
        if websocket in self.connection_timestamps:
            del self.connection_timestamps[websocket]

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
