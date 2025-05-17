import requests

# Base URL
BASE_URL = "http://localhost:8000"

# User details
USERNAME = "Sosiggg4"
EMAIL = "ivi.salski.35+test3@gmail.com"
PASSWORD = "admin123"

def register_user():
    """Register a user"""
    url = f"{BASE_URL}/api/v1/auth/register"
    data = {
        "username": USERNAME,
        "email": EMAIL,
        "password": PASSWORD
    }

    print(f"Registering user: {USERNAME}")
    print(f"URL: {url}")
    print(f"Data: {data}")

    try:
        response = requests.post(url, json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")

        return response.status_code == 201
    except Exception as e:
        print(f"Error: {e}")
        return False

def get_token():
    """Get a JWT token"""
    url = f"{BASE_URL}/api/v1/auth/token"
    data = {
        "username": USERNAME,
        "password": PASSWORD
    }

    print(f"Getting token for user: {USERNAME}")
    print(f"URL: {url}")
    print(f"Data: {data}")

    try:
        response = requests.post(url, data=data)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            token_data = response.json()
            token = token_data["access_token"]
            print(f"JWT Token: {token}")

            print("\nUse this token in your requests:")
            print(f"Authorization: Bearer {token}")

            print("\nFor WebSocket connections:")
            print(f"ws://localhost:8000/api/v1/sensor/ws?token={token}")

            return token
        else:
            print(f"Error: {response.text}")
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    # Try to register the user
    register_success = register_user()

    # Get a token
    if register_success or True:  # Try to get token even if registration fails
        token = get_token()
        if token:
            print("\nSuccess! You can now use this token in your ESP32 code.")

            # Write token to a file for easy access
            with open("token.txt", "w") as f:
                f.write(token)
