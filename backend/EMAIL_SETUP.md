# Email Setup for EnviroSense

This document explains how to set up email functionality for the EnviroSense application.

## Gmail Configuration

The application is configured to use Gmail's SMTP server by default. To use Gmail for sending emails, you need to:

1. Have a Gmail account
2. Generate an App Password (not your regular Gmail password)

### Generating a Gmail App Password

1. Go to your Google Account settings: https://myaccount.google.com/
2. Select "Security" from the left menu
3. Under "Signing in to Google," select "2-Step Verification" (you must have this enabled)
4. At the bottom of the page, select "App passwords"
5. Select "Mail" as the app and "Other (Custom name)" as the device
6. Enter "EnviroSense" as the name
7. Click "Generate"
8. Google will display a 16-character password - copy this password

## Environment Variables

Create a `.env` file in the `backend` directory based on the `.env.example` template:

```
# Email Configuration
MAIL_USERNAME=your_gmail_address@gmail.com
MAIL_PASSWORD=your_16_character_app_password
MAIL_FROM=your_gmail_address@gmail.com
MAIL_PORT=587
MAIL_SERVER=smtp.gmail.com
MAIL_FROM_NAME=EnviroSense
MAIL_TLS=True
MAIL_SSL=False
```

Replace `your_gmail_address@gmail.com` with your actual Gmail address and `your_16_character_app_password` with the App Password you generated.

## Testing Email Functionality

You can test the email functionality using the provided script:

```bash
python send_token_email.py ivi.salski.35@gmail.com
```

This will send an authentication token to the specified email address.

## Troubleshooting

If emails are not being sent:

1. Check that your App Password is correct
2. Verify that your Gmail account doesn't have additional security restrictions
3. Check the application logs for any SMTP errors
4. Make sure your `.env` file is in the correct location and has the correct format

## Using a Different Email Provider

If you want to use a different email provider:

1. Update the SMTP settings in your `.env` file:
   - `MAIL_SERVER`: Your provider's SMTP server
   - `MAIL_PORT`: The SMTP port (usually 587 for TLS or 465 for SSL)
   - `MAIL_TLS` and `MAIL_SSL`: Set according to your provider's requirements
2. Update the username and password accordingly

## Email Templates

Email templates are stored in the `backend/app/templates/email` directory. You can customize these templates to change the appearance of the emails.
