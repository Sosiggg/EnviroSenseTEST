import pytest
from fastapi.testclient import TestClient

def test_get_sensor_data_empty(client, token):
    """Test getting sensor data when none exists"""
    response = client.get(
        "/api/v1/sensor/data",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json() == []

def test_get_sensor_data_unauthorized(client):
    """Test getting sensor data without authentication"""
    response = client.get("/api/v1/sensor/data")
    assert response.status_code == 401

def test_get_sensor_data_with_data(client, token, test_db, test_user):
    """Test getting sensor data after adding some data"""
    from app.models.sensor import SensorData
    
    # Add some test sensor data
    sensor_data = SensorData(
        temperature=25.5,
        humidity=60.2,
        obstacle=False,
        user_id=test_user["id"]
    )
    test_db.add(sensor_data)
    test_db.commit()
    
    # Get the sensor data
    response = client.get(
        "/api/v1/sensor/data",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["temperature"] == 25.5
    assert response.json()[0]["humidity"] == 60.2
    assert response.json()[0]["obstacle"] is False
