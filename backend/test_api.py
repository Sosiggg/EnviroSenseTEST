import requests
import json

# Base URL
BASE_URL = "http://localhost:8000"

def register_user():
    """Register a test user"""
    url = f"{BASE_URL}/api/v1/auth/register"
    data = {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword"
    }
    
    response = requests.post(url, json=data)
    print(f"Register User Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    return response.status_code == 201

def get_token():
    """Get a JWT token"""
    url = f"{BASE_URL}/api/v1/auth/token"
    data = {
        "username": "testuser",
        "password": "testpassword"
    }
    
    response = requests.post(url, data=data)
    print(f"Get Token Status Code: {response.status_code}")
    
    if response.status_code == 200:
        token_data = response.json()
        token = token_data["access_token"]
        print(f"JWT Token: {token}")
        return token
    else:
        print(f"Error: {response.text}")
        return None

def get_user_info(token):
    """Get user info using the token"""
    url = f"{BASE_URL}/api/v1/auth/me"
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(url, headers=headers)
    print(f"Get User Info Status Code: {response.status_code}")
    
    if response.status_code == 200:
        user_data = response.json()
        print(f"User Info: {json.dumps(user_data, indent=2)}")
    else:
        print(f"Error: {response.text}")

def main():
    """Main function"""
    # Try to register a user (might fail if user already exists)
    register_user()
    
    # Get a token
    token = get_token()
    if token:
        # Get user info
        get_user_info(token)
        
        # Print WebSocket connection info
        print("\nWebSocket Connection:")
        print(f"ws://localhost:8000/api/v1/sensor/ws?token={token}")

if __name__ == "__main__":
    main()
