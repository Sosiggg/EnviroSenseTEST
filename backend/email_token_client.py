"""
Email Token Client

This script provides a simple command-line interface to request an authentication token
via email for the EnviroSense application.

Usage:
    python email_token_client.py

The script will prompt for an email address and then send a request to the API
to send an authentication token to that email.
"""

import requests
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get base URL from environment variable or use default
BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")

def main():
    """Main function to run the email token client."""
    print("EnviroSense Email Token Client")
    print("==============================")
    print(f"API Base URL: {BASE_URL}")
    print()
    
    # Get email from user
    email = input("Enter your email address: ")
    
    # Validate email format
    if not "@" in email or not "." in email:
        print("Invalid email format. Please enter a valid email address.")
        return
    
    # Confirm with user
    print(f"\nSending authentication token to: {email}")
    confirm = input("Confirm? (y/n): ")
    
    if confirm.lower() != "y":
        print("Operation cancelled.")
        return
    
    # Send request to API
    url = f"{BASE_URL}/api/v1/auth/email-token"
    
    try:
        print(f"\nSending request to {url}...")
        response = requests.post(
            url,
            json={"email": email}
        )
        
        # Check response
        if response.status_code == 200:
            print("\nSuccess! If your email is registered, you will receive an authentication token.")
            print("Please check your email inbox (and spam folder).")
        else:
            print(f"\nError: {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"\nError: {e}")

if __name__ == "__main__":
    main()
