"""
Test script for brute force protection.
This script will:
1. Create a test user if it doesn't exist
2. Attempt to log in with incorrect password multiple times
3. Verify that the account gets locked after 5 failed attempts
4. Try to log in with correct credentials to verify lockout
"""
import requests
import time
import sys
import os
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# API URL - use the deployed Render URL or local URL
BASE_URL = "https://envirosense-2khv.onrender.com/api/v1"

# Uncomment to test locally
# BASE_URL = "http://localhost:8000/api/v1"

# Enable debug mode to see detailed request/response info
DEBUG = True

# Test user credentials
TEST_USERNAME = "testuser_brute_force"
TEST_PASSWORD = "correctpassword123"
WRONG_PASSWORD = "wrongpassword123"

def create_test_user():
    """Create a test user if it doesn't exist."""
    print(f"Creating test user: {TEST_USERNAME}")

    # Register the test user
    register_url = f"{BASE_URL}/auth/register"
    register_data = {
        "username": TEST_USERNAME,
        "email": f"{TEST_USERNAME}@example.com",
        "password": TEST_PASSWORD
    }

    try:
        if DEBUG:
            print(f"POST {register_url}")
            print(f"Request data: {json.dumps(register_data, indent=2)}")

        response = requests.post(register_url, json=register_data)

        if DEBUG:
            print(f"Response status: {response.status_code}")
            print(f"Response headers: {dict(response.headers)}")
            try:
                print(f"Response body: {json.dumps(response.json(), indent=2)}")
            except:
                print(f"Response text: {response.text}")

        if response.status_code == 201:
            print("Test user created successfully.")
            return True
        elif response.status_code == 400 and "already registered" in response.text:
            print("Test user already exists.")
            return True
        else:
            print(f"Failed to create test user. Status code: {response.status_code}")
            print(f"Response: {response.text}")

            # Try to log in with the user in case it already exists
            print("Attempting to log in with the test user in case it already exists...")
            login_response = attempt_login(TEST_USERNAME, TEST_PASSWORD)
            if login_response.status_code == 200:
                print("Test user already exists and credentials are valid.")
                return True

            return False
    except Exception as e:
        print(f"Exception during user creation: {str(e)}")
        return False

def attempt_login(username, password):
    """Attempt to log in with the given credentials."""
    login_url = f"{BASE_URL}/auth/token"
    login_data = {
        "username": username,
        "password": password
    }

    try:
        if DEBUG:
            print(f"POST {login_url}")
            print(f"Login attempt for user: {username}")

        # Use form data for login as required by OAuth2PasswordRequestForm
        response = requests.post(
            login_url,
            data=login_data,
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )

        if DEBUG:
            print(f"Response status: {response.status_code}")
            try:
                print(f"Response body: {json.dumps(response.json(), indent=2)}")
            except:
                print(f"Response text: {response.text}")

        return response
    except Exception as e:
        print(f"Exception during login attempt: {str(e)}")
        # Create a mock response for error handling
        class MockResponse:
            def __init__(self):
                self.status_code = 500
                self.text = str(e)

            def json(self):
                return {"detail": str(e)}

        return MockResponse()

def test_brute_force_protection():
    """Test the brute force protection feature."""
    # Create test user
    if not create_test_user():
        print("Failed to create test user. Exiting.")
        return

    print("\n--- Testing Brute Force Protection ---")

    # First, make sure we can log in with correct credentials
    print("\nAttempting login with correct credentials...")
    response = attempt_login(TEST_USERNAME, TEST_PASSWORD)

    if response.status_code == 200:
        print("Login successful with correct credentials.")
    else:
        print(f"Login failed with correct credentials. Status code: {response.status_code}")
        print(f"Response: {response.text}")
        print("Exiting test.")
        return

    # Now attempt to log in with incorrect password multiple times
    print("\nAttempting login with incorrect password multiple times...")

    account_locked = False
    for i in range(6):  # Try 6 times (one more than the limit)
        print(f"\nAttempt {i+1} with incorrect password...")
        response = attempt_login(TEST_USERNAME, WRONG_PASSWORD)

        print(f"Status code: {response.status_code}")
        print(f"Response: {response.text}")

        if "Account locked" in response.text:
            print("\n✅ SUCCESS: Account was locked after multiple failed attempts!")
            account_locked = True
            break

        # Small delay between attempts
        time.sleep(1)

    if not account_locked:
        print("\n⚠️ WARNING: Account was not locked after 6 failed attempts.")
        print("This could be because:")
        print("1. The brute force protection is not working")
        print("2. The deployment is still in progress")
        print("3. The database migration hasn't been applied yet")
        print("\nContinuing with the test anyway...")

    # Now try with correct password to verify lockout
    print("\nAttempting login with correct credentials after lockout...")
    response = attempt_login(TEST_USERNAME, TEST_PASSWORD)

    if response.status_code == 401 and "Account locked" in response.text:
        print("✅ SUCCESS: Account is locked even with correct credentials!")
        print(f"Response: {response.text}")
    else:
        print("⚠️ NOTE: Account should be locked but login was successful or failed for other reasons.")
        print(f"Status code: {response.status_code}")
        print(f"Response: {response.text}")

        if response.status_code == 200:
            print("\nThis suggests that either:")
            print("1. The brute force protection is not working")
            print("2. The deployment is still in progress")
            print("3. The database migration hasn't been applied yet")

    print("\nBrute force protection test completed.")

if __name__ == "__main__":
    test_brute_force_protection()
