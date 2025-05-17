import requests
import json

def get_token_with_requests(username, password):
    """Get a JWT token using requests"""
    url = "http://localhost:8000/api/v1/auth/token"
    data = {
        "username": username,
        "password": password
    }

    try:
        response = requests.post(url, data=data)
        if response.status_code == 200:
            try:
                response_data = response.json()
                token = response_data.get('access_token')
                if token:
                    print(f"Successfully obtained token for {username}")
                    print(f"\nToken: {token}")
                    print("\nUse this token in your requests:")
                    print(f"Authorization: Bearer {token}")
                    print("\nFor WebSocket connections:")
                    print(f"ws://localhost:8000/api/v1/sensor/ws?token={token}")
                    print(f"wss://envirosense-2khv.onrender.com/api/v1/sensor/ws?token={token}")

                    # Print curl command for reference
                    print("\nCurl command to get token:")
                    print(f'curl -X POST "http://localhost:8000/api/v1/auth/token" \\')
                    print(f'  -H "Content-Type: application/x-www-form-urlencoded" \\')
                    print(f'  -d "username={username}&password={password}"')

                    return token
                else:
                    print("No token found in response")
                    print(f"Response: {response_data}")
            except json.JSONDecodeError:
                print("Failed to parse JSON response")
                print(f"Response: {response.text}")
        else:
            print(f"Request failed with status code {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"Error making request: {e}")

    return None

if __name__ == "__main__":
    username = "Sosiggg"
    password = "admin123"

    print(f"Getting token for user: {username}")
    token = get_token_with_requests(username, password)

    if token:
        # Save token to file for easy access
        with open("new_token.txt", "w") as f:
            f.write(token)
        print("\nToken saved to new_token.txt")
