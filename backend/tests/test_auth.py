import pytest
from fastapi.testclient import TestClient

def test_register_user(client):
    """Test user registration"""
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "newuser",
            "email": "newuser@example.com",
            "password": "newpassword"
        }
    )
    assert response.status_code == 201
    assert response.json() == {"message": "User created successfully"}

def test_register_existing_user(client, test_user):
    """Test registration with existing username"""
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": test_user["username"],
            "email": "another@example.com",
            "password": "password123"
        }
    )
    assert response.status_code == 400
    assert "Username already registered" in response.json()["detail"]

def test_login_success(client, test_user):
    """Test successful login"""
    response = client.post(
        "/api/v1/auth/token",
        data={
            "username": test_user["username"],
            "password": test_user["password"]
        }
    )
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["token_type"] == "bearer"

def test_login_invalid_credentials(client):
    """Test login with invalid credentials"""
    response = client.post(
        "/api/v1/auth/token",
        data={
            "username": "nonexistent",
            "password": "wrongpassword"
        }
    )
    assert response.status_code == 401
    assert "Incorrect username or password" in response.json()["detail"]

def test_get_current_user(client, token):
    """Test getting current user info"""
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"
    assert response.json()["email"] == "test@example.com"

def test_get_current_user_invalid_token(client):
    """Test getting user info with invalid token"""
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalidtoken"}
    )
    assert response.status_code == 401
