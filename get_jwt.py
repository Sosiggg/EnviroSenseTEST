import requests
import time

def get_token(username, password, base_url="http://localhost:8000"):
    """Get a JWT token for the given username and password."""
    url = f"{base_url}/api/v1/auth/token"
    
    print(f"Getting token for user: {username}")
    print(f"URL: {url}")
    
    try:
        start_time = time.time()
        response = requests.post(
            url,
            data={
                "username": username,
                "password": password
            },
            timeout=10
        )
        end_time = time.time()
        
        print(f"Request took {end_time - start_time:.2f} seconds")
        print(f"Status code: {response.status_code}")
        
        if response.status_code == 200:
            token_data = response.json()
            token = token_data["access_token"]
            print(f"JWT Token: {token}")
            
            # Save token to file
            with open("jwt_token.txt", "w") as f:
                f.write(token)
            
            print("Token saved to jwt_token.txt")
            return token
        else:
            print(f"Error: {response.text}")
            return None
    except requests.exceptions.Timeout:
        print("Request timed out after 10 seconds")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    # Use the credentials from the test
    username = "Sosiggg2"
    password = "admin123"
    
    token = get_token(username, password)
    
    if token:
        print("\nUse this token in your ESP32 code:")
        print(f"const char* jwt_token = \"{token}\";")
        
        print("\nFor WebSocket connections:")
        print(f"ws://localhost:8000/api/v1/sensor/ws?token={token}")
        print(f"wss://envirosense-2khv.onrender.com/api/v1/sensor/ws?token={token}")
