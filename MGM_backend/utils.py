from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os



def send_registration_email(to_email, user_name):

    EMAIL_HOST = os.getenv("EMAIL_HOST")
    EMAIL_PORT_RAW = os.getenv("EMAIL_PORT")
    EMAIL_USER = os.getenv("EMAIL_USER")
    EMAIL_PASS = os.getenv("EMAIL_PASS")
    EMAIL_FROM = os.getenv("EMAIL_FROM")

    if not EMAIL_HOST or not EMAIL_PORT_RAW or not EMAIL_USER or not EMAIL_PASS or not EMAIL_FROM:
        raise EnvironmentError("Missing one or more required email environment variables: EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS, EMAIL_FROM")
    try:
        EMAIL_PORT = int(EMAIL_PORT_RAW)
    except Exception:
        raise ValueError("EMAIL_PORT environment variable must be an integer.")

    subject = "Welcome to MGM Hospital App!"
    body = (
        f"Hello {user_name},\n\n"
        "You have registered in MGM Hospital's app.\n\n"
        "Thank you!"
    )

    msg = MIMEMultipart()
    msg["From"] = str(EMAIL_FROM)
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    try:
        with smtplib.SMTP_SSL(EMAIL_HOST, EMAIL_PORT) as server:
            server.login(str(EMAIL_USER), str(EMAIL_PASS))
            server.sendmail(str(EMAIL_FROM), to_email, msg.as_string())
        print(f"Registration email sent to {to_email}")
        return True
    except Exception as e:
        print(f"Could not send email: {e}")
        return False


def send_email(to_email, subject, body):
    # Replace with your SMTP settings
    smtp_server = "smtp.example.com"
    smtp_port = 587
    smtp_user = "your@email.com"
    smtp_password = "yourpassword"

    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = smtp_user
    msg["To"] = to_email

    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.sendmail(smtp_user, [to_email], msg.as_string())


        
# Use environment for secrets if possible
SECRET_KEY = os.getenv("SECRET_KEY", "Priyans3628p")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 90  # 90 days

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

from typing import Optional
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)