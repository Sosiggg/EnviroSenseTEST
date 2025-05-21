# Deployment Instructions for Email Functionality

This document provides instructions for deploying the email functionality to Render.

## 1. Update Environment Variables on Render

Add the following environment variables to your Render service:

```
MAIL_USERNAME=notismes18@gmail.com
MAIL_PASSWORD=pmvqvtcwpqgsoequ
MAIL_FROM=notismes18@gmail.com
MAIL_PORT=587
MAIL_SERVER=smtp.gmail.com
MAIL_FROM_NAME=EnviroSense
MAIL_STARTTLS=True
MAIL_SSL_TLS=False
```

## 2. Deploy the Code

1. Commit all changes to your repository:
   ```
   git add backend/app/core/email.py backend/app/templates/email/ backend/.env.example backend/send_token_email.py backend/email_token_client.py backend/EMAIL_SETUP.md backend/requirements.txt backend/app/api/v1/endpoints/auth.py
   git commit -m "Add email functionality for sending authentication tokens"
   git push
   ```

2. Render will automatically deploy the changes when you push to your repository.

## 3. Test the Deployed Functionality

Once deployed, you can test the email functionality using the following curl command:

```
curl -X POST "https://envirosense-2khv.onrender.com/api/v1/auth/email-token" -H "Content-Type: application/json" -d "{\"email\":\"ivi.salski.35@gmail.com\"}"
```

Or using the provided Python script:

```
python send_token_email.py ivi.salski.35@gmail.com
```

## 4. Troubleshooting

If you encounter issues with Gmail:

1. Make sure the App Password is correct and entered without spaces
2. Check that "Less secure app access" is enabled for your Gmail account
3. Check the Render logs for any SMTP errors
4. Consider using a different email service like SendGrid or Mailgun

## 5. Alternative Email Services

If Gmail continues to cause issues, consider using a service like SendGrid:

1. Sign up for a free SendGrid account
2. Get an API key
3. Update the environment variables:
   ```
   MAIL_SERVER=smtp.sendgrid.net
   MAIL_USERNAME=apikey
   MAIL_PASSWORD=your_sendgrid_api_key
   ```
