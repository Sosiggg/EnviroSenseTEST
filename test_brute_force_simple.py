"""
Simple test script for brute force protection.
This script will:
1. Attempt to log in with incorrect password multiple times
2. Verify that the account gets locked after 5 failed attempts
3. Try to log in with correct credentials to verify lockout
"""
import requests
import time

# API URL - use the deployed Render URL
BASE_URL = "https://envirosense-2khv.onrender.com/api/v1"

# Test user credentials - replace with your own test user
TEST_USERNAME = "your_test_username"
TEST_PASSWORD = "your_correct_password"
WRONG_PASSWORD = "wrong_password"

def attempt_login(username, password):
    """Attempt to log in with the given credentials."""
    login_url = f"{BASE_URL}/auth/token"
    login_data = {
        "username": username,
        "password": password
    }
    
    print(f"Attempting login for user: {username}")
    
    # Use form data for login as required by OAuth2PasswordRequestForm
    response = requests.post(
        login_url, 
        data=login_data,
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    
    print(f"Status code: {response.status_code}")
    print(f"Response: {response.text}")
    print("-" * 50)
    
    return response

def test_brute_force_protection():
    """Test the brute force protection feature."""
    print("\n--- Testing Brute Force Protection ---\n")
    
    # First, make sure we can log in with correct credentials
    print("Step 1: Verifying login with correct credentials...")
    response = attempt_login(TEST_USERNAME, TEST_PASSWORD)
    
    if response.status_code != 200:
        print("Login failed with correct credentials. Please check your credentials.")
        return
    
    print("Login successful with correct credentials.\n")
    
    # Now attempt to log in with incorrect password multiple times
    print("Step 2: Attempting login with incorrect password multiple times...")
    
    for i in range(6):  # Try 6 times (one more than the limit)
        print(f"Attempt {i+1} with incorrect password...")
        response = attempt_login(TEST_USERNAME, WRONG_PASSWORD)
        
        if "Account locked" in response.text:
            print("\nSUCCESS: Account was locked after multiple failed attempts!")
            break
        
        # Small delay between attempts
        time.sleep(1)
    
    # Now try with correct password to verify lockout
    print("\nStep 3: Attempting login with correct credentials after lockout...")
    response = attempt_login(TEST_USERNAME, TEST_PASSWORD)
    
    if response.status_code == 401 and "Account locked" in response.text:
        print("SUCCESS: Account is locked even with correct credentials!")
    else:
        print("FAILURE: Account should be locked but login was successful or failed for other reasons.")
    
    print("\nBrute force protection test completed.")

if __name__ == "__main__":
    # Replace these with your actual test user credentials before running
    TEST_USERNAME = input("Enter test username: ")
    TEST_PASSWORD = input("Enter correct password: ")
    WRONG_PASSWORD = input("Enter wrong password: ")
    
    test_brute_force_protection()
