from fastapi.testclient import TestClient
import json
import sys
import os

# Add the current directory to the Python path
sys.path.insert(0, os.path.abspath("."))

# Import the app
from app.main import app

# Create a test client
client = TestClient(app)

def test_register_user():
    """Test user registration"""
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpassword"
        }
    )
    print(f"Register User Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    return response.status_code == 201

def test_login():
    """Test login and get token"""
    response = client.post(
        "/api/v1/auth/token",
        data={
            "username": "testuser",
            "password": "testpassword"
        }
    )
    print(f"Login Status Code: {response.status_code}")
    
    if response.status_code == 200:
        token_data = response.json()
        token = token_data["access_token"]
        print(f"JWT Token: {token}")
        return token
    else:
        print(f"Error: {response.text}")
        return None

def test_get_user_info(token):
    """Test getting user info"""
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    print(f"Get User Info Status Code: {response.status_code}")
    
    if response.status_code == 200:
        user_data = response.json()
        print(f"User Info: {json.dumps(user_data, indent=2)}")
    else:
        print(f"Error: {response.text}")

def main():
    """Main function"""
    # Try to register a user (might fail if user already exists)
    test_register_user()
    
    # Get a token
    token = test_login()
    if token:
        # Get user info
        test_get_user_info(token)
        
        # Print WebSocket connection info
        print("\nWebSocket Connection:")
        print(f"ws://localhost:8000/api/v1/sensor/ws?token={token}")

if __name__ == "__main__":
    main()
