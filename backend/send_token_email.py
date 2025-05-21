"""
Script to send an authentication token via email to a specified user.
This is a utility script for testing the email functionality.

Usage:
    python send_token_email.py <email>

Example:
    python send_token_email.py ivi.salski.35@gmail.com
"""

import sys
import requests
import os
from dotenv import load_dotenv

# Load environment variables from .env file if it exists
load_dotenv()

# Default base URL
DEFAULT_BASE_URL = "http://localhost:8000"

def send_token_email(email, base_url=None):
    """
    Send an authentication token via email to the specified user.
    
    Args:
        email (str): The email address to send the token to
        base_url (str, optional): The base URL of the API. Defaults to environment variable or localhost.
        
    Returns:
        bool: True if the request was successful, False otherwise
    """
    # Get base URL from environment variable or use default
    if base_url is None:
        base_url = os.getenv("API_BASE_URL", DEFAULT_BASE_URL)
    
    # Construct the URL
    url = f"{base_url}/api/v1/auth/email-token"
    
    # Make the request
    print(f"Sending token email request to {url}")
    print(f"Email: {email}")
    
    try:
        response = requests.post(
            url,
            json={"email": email}
        )
        
        # Check if the request was successful
        if response.status_code == 200:
            print("Request successful!")
            print(response.json())
            return True
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"Exception: {e}")
        return False

if __name__ == "__main__":
    # Check if email was provided as command line argument
    if len(sys.argv) < 2:
        print("Please provide an email address as a command line argument.")
        print("Usage: python send_token_email.py <email>")
        sys.exit(1)
    
    # Get email from command line argument
    email = sys.argv[1]
    
    # Optional base URL from command line
    base_url = None
    if len(sys.argv) > 2:
        base_url = sys.argv[2]
    
    # Send token email
    success = send_token_email(email, base_url)
    
    # Exit with appropriate status code
    sys.exit(0 if success else 1)
