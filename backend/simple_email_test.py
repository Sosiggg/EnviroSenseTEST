"""
Simple email test using Python's built-in email functionality.
"""

import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def send_email():
    """Send a test email using Python's built-in email functionality."""
    # Get email settings from environment variables
    smtp_server = os.getenv("MAIL_SERVER", "smtp.gmail.com")
    smtp_port = int(os.getenv("MAIL_PORT", "587"))
    smtp_username = os.getenv("MAIL_USERNAME", "")
    smtp_password = os.getenv("MAIL_PASSWORD", "")
    from_email = os.getenv("MAIL_FROM", "noreply@envirosense.com")
    
    # Print settings for debugging
    print(f"SMTP Server: {smtp_server}")
    print(f"SMTP Port: {smtp_port}")
    print(f"SMTP Username: {smtp_username}")
    print(f"From Email: {from_email}")
    
    # Check if we have credentials
    if not smtp_username or not smtp_password:
        print("Email credentials not configured. Email not sent.")
        return False
    
    # Email details
    to_email = "ivi.salski.35@gmail.com"
    subject = "Test Email from EnviroSense"
    
    # Create message
    msg = MIMEMultipart()
    msg["From"] = from_email
    msg["To"] = to_email
    msg["Subject"] = subject
    
    # Email body
    body = """
    <html>
    <body>
        <h2>Test Email from EnviroSense</h2>
        <p>This is a test email from the EnviroSense application.</p>
        <p>If you received this email, the email functionality is working correctly.</p>
        <p>Best regards,<br>The EnviroSense Team</p>
    </body>
    </html>
    """
    
    # Attach body to message
    msg.attach(MIMEText(body, "html"))
    
    try:
        # Connect to SMTP server
        print(f"Connecting to SMTP server: {smtp_server}:{smtp_port}")
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.ehlo()
        
        # Start TLS
        print("Starting TLS")
        server.starttls()
        server.ehlo()
        
        # Login
        print(f"Logging in as: {smtp_username}")
        server.login(smtp_username, smtp_password)
        
        # Send email
        print(f"Sending email to: {to_email}")
        server.sendmail(from_email, to_email, msg.as_string())
        
        # Close connection
        server.quit()
        
        print("Email sent successfully!")
        return True
    
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

if __name__ == "__main__":
    send_email()
