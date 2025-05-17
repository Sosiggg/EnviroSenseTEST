import pytest
import json
from fastapi.testclient import TestClient
from fastapi.websockets import WebSocketDisconnect

def test_websocket_connection_with_token(client, token):
    """Test WebSocket connection with valid token"""
    with client.websocket_connect(f"/api/v1/sensor/ws?token={token}") as websocket:
        # Send a test message
        data = {
            "temperature": 25.5,
            "humidity": 60.2,
            "obstacle": False
        }
        websocket.send_text(json.dumps(data))
        
        # Receive the response
        response = websocket.receive_text()
        response_data = json.loads(response)
        
        # Check the response
        assert response_data["status"] == "success"
        assert response_data["message"] == "Data received"

def test_websocket_connection_without_token(client):
    """Test WebSocket connection without token"""
    with pytest.raises(WebSocketDisconnect) as excinfo:
        with client.websocket_connect("/api/v1/sensor/ws") as websocket:
            pass
    
    # Check that the connection was closed with the correct code
    assert excinfo.value.code == 1008  # Policy violation

def test_websocket_connection_invalid_token(client):
    """Test WebSocket connection with invalid token"""
    with pytest.raises(WebSocketDisconnect) as excinfo:
        with client.websocket_connect("/api/v1/sensor/ws?token=invalidtoken") as websocket:
            pass
    
    # Check that the connection was closed with the correct code
    assert excinfo.value.code == 1008  # Policy violation

def test_websocket_invalid_json(client, token):
    """Test sending invalid JSON to WebSocket"""
    with client.websocket_connect(f"/api/v1/sensor/ws?token={token}") as websocket:
        # Send invalid JSON
        websocket.send_text("not a json")
        
        # Receive the response
        response = websocket.receive_text()
        response_data = json.loads(response)
        
        # Check the response
        assert response_data["status"] == "error"
        assert response_data["message"] == "Invalid JSON data"
