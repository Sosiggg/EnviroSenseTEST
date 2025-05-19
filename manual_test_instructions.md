# Manual Testing Instructions for Brute Force Protection

Follow these steps to manually test the brute force protection feature:

## Prerequisites
- The EnviroSense backend should be deployed and running
- You should have a test user account (or create one)

## Test Steps

### 1. Create a Test User (if needed)
- Go to the registration endpoint: `https://envirosense-2khv.onrender.com/api/v1/auth/register`
- Create a test user with the following details:
  ```json
  {
    "username": "testuser_brute_force",
    "email": "testuser_brute_force@example.com",
    "password": "correctpassword123"
  }
  ```

### 2. Verify Normal Login Works
- Go to the login endpoint: `https://envirosense-2khv.onrender.com/api/v1/auth/token`
- Log in with the correct credentials:
  - Username: `testuser_brute_force`
  - Password: `correctpassword123`
- You should receive an access token in the response

### 3. Test Brute Force Protection
- Attempt to log in with incorrect password 5 times:
  - Username: `testuser_brute_force`
  - Password: `wrongpassword123`
- On the 5th or 6th attempt, you should receive an error message indicating that the account is locked
- The error message should include the remaining lockout time (approximately 30 minutes)

### 4. Verify Account Lockout
- Now try to log in with the correct credentials:
  - Username: `testuser_brute_force`
  - Password: `correctpassword123`
- You should still receive the account lockout error message
- This confirms that the account is locked even with correct credentials

### 5. Wait for Lockout to Expire
- Wait for 30 minutes
- Try to log in with the correct credentials again
- You should now be able to log in successfully

## Expected Results
- After 5 failed login attempts, the account should be locked for 30 minutes
- During the lockout period, login attempts should fail even with correct credentials
- After the lockout period expires, login should work again with correct credentials

## Tools for Testing
You can use any of these tools for testing:
- Postman
- cURL
- The Flutter app login screen
- Any HTTP client that can send POST requests

## Example cURL Commands

### Register User
```bash
curl -X POST https://envirosense-2khv.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser_brute_force","email":"testuser_brute_force@example.com","password":"correctpassword123"}'
```

### Login (Correct Credentials)
```bash
curl -X POST https://envirosense-2khv.onrender.com/api/v1/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser_brute_force&password=correctpassword123"
```

### Login (Incorrect Credentials)
```bash
curl -X POST https://envirosense-2khv.onrender.com/api/v1/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser_brute_force&password=wrongpassword123"
```
