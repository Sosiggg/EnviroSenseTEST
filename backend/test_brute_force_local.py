"""
Local test script for brute force protection.
This script directly tests the authentication logic without using the API.
"""
import sys
import os
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session

# Add the parent directory to the path so we can import from app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine, get_db
from app.models.user import User
from app.core.auth import get_password_hash, authenticate_user, verify_password

# Test user credentials
TEST_USERNAME = "testuser_brute_force_local"
TEST_PASSWORD = "correctpassword123"
WRONG_PASSWORD = "wrongpassword123"

def get_db_session():
    """Get a database session."""
    db = Session(engine)
    try:
        return db
    except:
        db.close()
        raise

def create_test_user(db: Session):
    """Create a test user if it doesn't exist."""
    print(f"Creating test user: {TEST_USERNAME}")
    
    # Check if user already exists
    user = db.query(User).filter(User.username == TEST_USERNAME).first()
    if user:
        print("Test user already exists.")
        
        # Reset user state
        user.failed_login_attempts = 0
        user.last_failed_login = None
        user.account_locked_until = None
        db.commit()
        print("Reset user state (failed attempts and lockout).")
        
        return user
    
    # Create new user
    hashed_password = get_password_hash(TEST_PASSWORD)
    new_user = User(
        username=TEST_USERNAME,
        email=f"{TEST_USERNAME}@example.com",
        hashed_password=hashed_password,
        is_active=True,
        failed_login_attempts=0,
        last_failed_login=None,
        account_locked_until=None
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    print("Test user created successfully.")
    
    return new_user

def test_brute_force_protection():
    """Test the brute force protection feature."""
    db = get_db_session()
    
    try:
        # Create or reset test user
        user = create_test_user(db)
        
        print("\n--- Testing Brute Force Protection ---")
        
        # First, make sure we can authenticate with correct credentials
        print("\nAttempting authentication with correct credentials...")
        auth_result = authenticate_user(db, TEST_USERNAME, TEST_PASSWORD)
        
        if auth_result:
            print("Authentication successful with correct credentials.")
        else:
            print("Authentication failed with correct credentials.")
            print("Exiting test.")
            return
        
        # Now attempt to authenticate with incorrect password multiple times
        print("\nAttempting authentication with incorrect password multiple times...")
        
        account_locked = False
        for i in range(6):  # Try 6 times (one more than the limit)
            print(f"\nAttempt {i+1} with incorrect password...")
            auth_result = authenticate_user(db, TEST_USERNAME, WRONG_PASSWORD)
            
            # Refresh user from database to see current state
            user = db.query(User).filter(User.username == TEST_USERNAME).first()
            print(f"Failed login attempts: {user.failed_login_attempts}")
            print(f"Account locked until: {user.account_locked_until}")
            
            if user.account_locked_until and user.account_locked_until > datetime.now(timezone.utc):
                print("\n✅ SUCCESS: Account was locked after multiple failed attempts!")
                account_locked = True
                break
        
        if not account_locked:
            print("\n❌ FAILURE: Account was not locked after 6 failed attempts.")
            print("The brute force protection is not working correctly.")
            return
        
        # Now try with correct password to verify lockout
        print("\nAttempting authentication with correct credentials after lockout...")
        auth_result = authenticate_user(db, TEST_USERNAME, TEST_PASSWORD)
        
        if not auth_result:
            print("✅ SUCCESS: Account is locked even with correct credentials!")
            
            # Calculate remaining lockout time
            user = db.query(User).filter(User.username == TEST_USERNAME).first()
            if user.account_locked_until:
                remaining_time = user.account_locked_until - datetime.now(timezone.utc)
                minutes = remaining_time.seconds // 60
                print(f"Account is locked for approximately {minutes} more minutes.")
        else:
            print("❌ FAILURE: Authentication succeeded despite account being locked!")
        
        print("\nBrute force protection test completed.")
        
    finally:
        db.close()

if __name__ == "__main__":
    test_brute_force_protection()
