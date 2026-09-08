import logging
import os
import smtplib
from email.message import EmailMessage

logger = logging.getLogger(__name__)

def send_verification_email(recipient: str, username: str, token: str) -> None:
    """Deliver an account-verification link through the configured SMTP server."""
    api_url = os.getenv('PUBLIC_API_URL', 'http://localhost:8000').rstrip('/')
    link = f'{api_url}/auth/verify-email?token={token}'
    host = os.getenv('SMTP_HOST')
    if not host:
        logger.warning('SMTP is not configured. Verification link for %s: %s', recipient, link)
        return
    _send(recipient, 'Verify your Chess account', f'Hi {username},\n\nVerify your Chess account: {link}\n\nIf you did not create this account, you can ignore this email.')

def send_reset_email(recipient: str, username: str, token: str) -> None:
    api_url = os.getenv('PUBLIC_API_URL', 'http://localhost:8000').rstrip('/')
    link = f'{api_url}/auth/reset-password?token={token}'
    _send(recipient, 'Reset your Chess password', f'Hi {username},\n\nReset your Chess password: {link}\n\nThis link expires in 30 minutes.')

def _send(recipient: str, subject: str, body: str) -> None:
    host = os.getenv('SMTP_HOST')
    if not host:
        logger.warning('SMTP is not configured. Email for %s: %s', recipient, body)
        return
    message = EmailMessage()
    message['Subject'] = subject
    message['From'] = os.getenv('SMTP_FROM', 'no-reply@chess.local')
    message['To'] = recipient
    message.set_content(body)
    with smtplib.SMTP(host, int(os.getenv('SMTP_PORT', '587')), timeout=15) as smtp:
        if os.getenv('SMTP_STARTTLS', 'true').lower() == 'true': smtp.starttls()
        if smtp_user := os.getenv('SMTP_USERNAME'):
            smtp.login(smtp_user, os.environ['SMTP_PASSWORD'])
        smtp.send_message(message)
