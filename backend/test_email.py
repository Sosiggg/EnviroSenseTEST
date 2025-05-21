"""
Test script for email functionality.
This script directly tests the email sending functionality without going through the API.
"""

import asyncio
import os
from dotenv import load_dotenv
from app.core.email import send_token_email

# Load environment variables
load_dotenv()

async def test_email():
    """Test sending an email."""
    print("Testing email functionality...")
    print(f"Using SMTP server: {os.getenv('MAIL_SERVER')}")
    print(f"Using username: {os.getenv('MAIL_USERNAME')}")
    
    # Send a test email
    email_to = "ivi.salski.35@gmail.com"
    token = "test_token_12345"
    username = "Test User"
    
    print(f"Sending test email to: {email_to}")
    
    # Send the email
    success = await send_token_email(email_to, token, username)
    
    if success:
        print("Email sent successfully!")
    else:
        print("Failed to send email.")

if __name__ == "__main__":
    # Run the async function
    asyncio.run(test_email())
