from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import os
from dotenv import load_dotenv

from app.db.database import get_db
from app.models.user import User
from app.schemas.token import TokenData

# Load environment variables
load_dotenv()

# Get JWT settings from environment variables with default values
SECRET_KEY = os.getenv("SECRET_KEY", "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/token")

# Verify password
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# Hash password
def get_password_hash(password):
    return pwd_context.hash(password)

# Get user by username
def get_user(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

# Authenticate user with brute force protection
def authenticate_user(db: Session, username: str, password: str):
    user = get_user(db, username)
    if not user:
        # Don't reveal that the user doesn't exist
        return False

    # Check if account is locked
    now = datetime.now(timezone.utc)
    if user.account_locked_until and user.account_locked_until > now:
        # Account is locked, but don't reveal this to the user
        # We'll return False which will result in the same error message
        return False

    # Verify password
    if not verify_password(password, user.hashed_password):
        # Password is incorrect, increment failed attempts
        user.failed_login_attempts += 1
        user.last_failed_login = now

        # Check if we need to lock the account (5 or more failed attempts)
        if user.failed_login_attempts >= 5:
            # Lock account for 30 minutes
            user.account_locked_until = now + timedelta(minutes=30)

        db.commit()
        return False

    # Password is correct, reset failed attempts
    user.failed_login_attempts = 0
    user.last_failed_login = None
    user.account_locked_until = None
    db.commit()

    return user

# Create access token
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# Get current user from token
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    user = get_user(db, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user

# Get current active user
async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# Verify WebSocket token
def verify_token(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            return None
        token_data = TokenData(username=username)
    except JWTError:
        return None
    user = get_user(db, username=token_data.username)
    return user
