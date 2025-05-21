"""
Email functionality for the EnviroSense application.
This module provides functions for sending emails, including password reset emails
and authentication token emails.
"""

import os
import logging
from pathlib import Path
from typing import List, Dict, Any
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from fastapi_mail.errors import ConnectionErrors
from pydantic import EmailStr
from jinja2 import Environment, select_autoescape, FileSystemLoader

# Create logger
logger = logging.getLogger(__name__)

# Get email settings from environment variables with default values
MAIL_USERNAME = os.getenv("MAIL_USERNAME", "")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD", "")
MAIL_FROM = os.getenv("MAIL_FROM", "noreply@envirosense.com")
MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))
MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.gmail.com")
MAIL_FROM_NAME = os.getenv("MAIL_FROM_NAME", "EnviroSense")
MAIL_STARTTLS = os.getenv("MAIL_STARTTLS", "True").lower() in ("true", "1", "t")
MAIL_SSL_TLS = os.getenv("MAIL_SSL_TLS", "False").lower() in ("true", "1", "t")

# Create templates directory if it doesn't exist
templates_dir = Path(__file__).parent.parent / "templates"
templates_dir.mkdir(exist_ok=True)

# Create email templates directory if it doesn't exist
email_templates_dir = templates_dir / "email"
email_templates_dir.mkdir(exist_ok=True)

# Configure Jinja2 templates
env = Environment(
    loader=FileSystemLoader(templates_dir),
    autoescape=select_autoescape(['html', 'xml'])
)

# Configure FastMail
conf = ConnectionConfig(
    MAIL_USERNAME=MAIL_USERNAME,
    MAIL_PASSWORD=MAIL_PASSWORD,
    MAIL_FROM=MAIL_FROM,
    MAIL_PORT=MAIL_PORT,
    MAIL_SERVER=MAIL_SERVER,
    MAIL_FROM_NAME=MAIL_FROM_NAME,
    MAIL_STARTTLS=MAIL_STARTTLS,
    MAIL_SSL_TLS=MAIL_SSL_TLS,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True,
    TEMPLATE_FOLDER=str(templates_dir)
)

async def send_email(
    email_to: List[EmailStr],
    subject: str,
    body: str,
    template_name: str = None,
    template_body: Dict[str, Any] = None
) -> bool:
    """
    Send an email to the specified recipients.

    Args:
        email_to: List of email addresses to send to
        subject: Email subject
        body: Plain text email body (used if template_name is None)
        template_name: Name of the template to use (optional)
        template_body: Dictionary of variables to pass to the template (optional)

    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    # Check if we have credentials
    if not MAIL_USERNAME or not MAIL_PASSWORD:
        logger.warning("Email credentials not configured. Email not sent.")
        return False

    try:
        # Determine the email content
        html_content = body

        # If a template is specified, use it
        if template_name and template_body:
            try:
                template = env.get_template(f"email/{template_name}")
                html_content = template.render(**template_body)
            except Exception as e:
                logger.error(f"Error rendering email template: {e}")
                # Fall back to plain text body
                html_content = body

        # Create the message
        message = MessageSchema(
            subject=subject,
            recipients=email_to,
            body=html_content,
            subtype=MessageType.html
        )

        # Send the email
        fm = FastMail(conf)
        await fm.send_message(message)
        logger.info(f"Email sent to {', '.join(email_to)}")
        return True

    except ConnectionErrors as e:
        logger.error(f"SMTP Connection error: {e}")
        return False
    except Exception as e:
        logger.error(f"Failed to send email: {e}")
        return False

async def send_token_email(email_to: EmailStr, token: str, username: str) -> bool:
    """
    Send an authentication token via email.

    Args:
        email_to: Email address to send to
        token: The authentication token
        username: The username of the recipient

    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    subject = "Your EnviroSense Authentication Token"
    body = f"""
    <html>
    <body>
        <h2>EnviroSense Authentication Token</h2>
        <p>Hello {username},</p>
        <p>Here is your authentication token for EnviroSense:</p>
        <p style="background-color: #f0f0f0; padding: 10px; font-family: monospace; font-size: 14px;">{token}</p>
        <p>You can use this token to authenticate with the EnviroSense API.</p>
        <p>This token will expire in 30 minutes.</p>
        <p>If you did not request this token, please ignore this email.</p>
        <p>Best regards,<br>The EnviroSense Team</p>
    </body>
    </html>
    """

    return await send_email(
        email_to=[email_to],
        subject=subject,
        body=body
    )

async def send_password_reset_email(email_to: EmailStr, reset_token: str, username: str) -> bool:
    """
    Send a password reset email.

    Args:
        email_to: Email address to send to
        reset_token: The password reset token
        username: The username of the recipient

    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    subject = "Reset Your EnviroSense Password"
    body = f"""
    <html>
    <body>
        <h2>EnviroSense Password Reset</h2>
        <p>Hello {username},</p>
        <p>We received a request to reset your password. If you didn't make this request, you can ignore this email.</p>
        <p>To reset your password, use the following token:</p>
        <p style="background-color: #f0f0f0; padding: 10px; font-family: monospace; font-size: 14px;">{reset_token}</p>
        <p>This token will expire in 1 hour.</p>
        <p>Best regards,<br>The EnviroSense Team</p>
    </body>
    </html>
    """

    return await send_email(
        email_to=[email_to],
        subject=subject,
        body=body
    )
