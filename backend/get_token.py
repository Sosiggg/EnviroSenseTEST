import requests
import argparse
import json

def get_token(username, password, base_url="http://localhost:8000"):
    """
    Get a JWT token for the given username and password.
    
    Args:
        username (str): The username
        password (str): The password
        base_url (str): The base URL of the API
        
    Returns:
        str: The JWT token
    """
    url = f"{base_url}/api/v1/auth/token"
    
    # Make the request
    response = requests.post(
        url,
        data={
            "username": username,
            "password": password
        }
    )
    
    # Check if the request was successful
    if response.status_code == 200:
        token_data = response.json()
        return token_data["access_token"]
    else:
        print(f"Error: {response.status_code}")
        print(response.text)
        return None

def register_user(username, email, password, base_url="http://localhost:8000"):
    """
    Register a new user.
    
    Args:
        username (str): The username
        email (str): The email
        password (str): The password
        base_url (str): The base URL of the API
        
    Returns:
        bool: True if registration was successful, False otherwise
    """
    url = f"{base_url}/api/v1/auth/register"
    
    # Make the request
    response = requests.post(
        url,
        json={
            "username": username,
            "email": email,
            "password": password
        }
    )
    
    # Check if the request was successful
    if response.status_code == 201:
        print("User registered successfully!")
        return True
    else:
        print(f"Error: {response.status_code}")
        print(response.text)
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Get a JWT token or register a user")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Login parser
    login_parser = subparsers.add_parser("login", help="Get a JWT token")
    login_parser.add_argument("--username", "-u", required=True, help="Username")
    login_parser.add_argument("--password", "-p", required=True, help="Password")
    login_parser.add_argument("--base-url", "-b", default="http://localhost:8000", help="Base URL of the API")
    
    # Register parser
    register_parser = subparsers.add_parser("register", help="Register a new user")
    register_parser.add_argument("--username", "-u", required=True, help="Username")
    register_parser.add_argument("--email", "-e", required=True, help="Email")
    register_parser.add_argument("--password", "-p", required=True, help="Password")
    register_parser.add_argument("--base-url", "-b", default="http://localhost:8000", help="Base URL of the API")
    
    args = parser.parse_args()
    
    if args.command == "login":
        token = get_token(args.username, args.password, args.base_url)
        if token:
            print(f"JWT Token: {token}")
            print("\nUse this token in your requests:")
            print(f"Authorization: Bearer {token}")
            print("\nFor WebSocket connections:")
            print(f"ws://localhost:8000/api/v1/sensor/ws?token={token}")
    elif args.command == "register":
        success = register_user(args.username, args.email, args.password, args.base_url)
        if success:
            print("Now you can get a token with:")
            print(f"python get_token.py login -u {args.username} -p {args.password}")
    else:
        parser.print_help()
