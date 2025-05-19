from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta, datetime, timezone
from pydantic import BaseModel, EmailStr
import secrets
import logging

from app.core.auth import (
    authenticate_user,
    create_access_token,
    get_current_active_user,
    get_password_hash,
    verify_password,
    ACCESS_TOKEN_EXPIRE_MINUTES
)
from app.db.database import get_db
from app.models.user import User
from app.schemas.token import Token
from app.schemas.user import UserCreate, User as UserSchema, UserUpdate, PasswordChange

# Create logger
logger = logging.getLogger(__name__)

# Define request models for forgot password
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

router = APIRouter()

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(user: UserCreate, db: Session = Depends(get_db)):
    # Check if username already exists
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    # Check if email already exists
    db_email = db.query(User).filter(User.email == user.email).first()
    if db_email:
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create new user
    hashed_password = get_password_hash(user.password)
    db_user = User(username=user.username, email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return {"message": "User created successfully"}

@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserSchema)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    return current_user

@router.put("/me", response_model=UserSchema)
async def update_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Check if username is being changed and if it already exists
    if user_update.username != current_user.username:
        db_user = db.query(User).filter(User.username == user_update.username).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Username already exists")

    # Check if email is being changed and if it already exists
    if user_update.email != current_user.email:
        db_email = db.query(User).filter(User.email == user_update.email).first()
        if db_email:
            raise HTTPException(status_code=400, detail="Email already exists")

    # Update user
    current_user.username = user_update.username
    current_user.email = user_update.email

    db.commit()
    db.refresh(current_user)

    return current_user

@router.post("/change-password", status_code=status.HTTP_200_OK)
async def change_password(
    password_change: PasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify current password
    if not verify_password(password_change.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")

    # Update password
    current_user.hashed_password = get_password_hash(password_change.new_password)
    db.commit()

    return {"message": "Password changed successfully"}

@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(
    request: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    """
    Handle forgot password request.
    In a production environment, this would:
    1. Generate a password reset token
    2. Store it in the database with an expiration time
    3. Send an email with a link to reset the password

    For this demo, we'll just log the request and return a success message.
    """
    # Find user by email
    user = db.query(User).filter(User.email == request.email).first()

    if not user:
        # Don't reveal that the user doesn't exist
        logger.info(f"Forgot password request for non-existent email: {request.email}")
        return {"message": "If your email is registered, you will receive password reset instructions."}

    # In a real implementation, we would:
    # 1. Generate a reset token
    reset_token = secrets.token_urlsafe(32)

    # 2. Store the token with an expiration time
    # user.reset_token = reset_token
    # user.reset_token_expires = datetime.now(timezone.utc) + timedelta(hours=1)
    # db.commit()

    # 3. Send an email with the reset link
    # reset_url = f"https://envirosense-app.com/reset-password?token={reset_token}"
    # send_email(user.email, "Password Reset", f"Click here to reset your password: {reset_url}")

    # For demo purposes, just log the token
    logger.info(f"Password reset requested for user: {user.username}")
    logger.info(f"Reset token generated: {reset_token}")

    return {"message": "If your email is registered, you will receive password reset instructions."}
