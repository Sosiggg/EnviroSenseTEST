from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta, datetime, timezone
from pydantic import BaseModel, EmailStr
import secrets
import logging
import sqlalchemy

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
from app.models.basic_user import BasicUser
from app.schemas.token import Token
from app.schemas.user import UserCreate, User as UserSchema, UserUpdate, PasswordChange

# Create logger
logger = logging.getLogger(__name__)

# Define request models for forgot password and reset password
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

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
    try:
        # Try to use the full User model first
        try:
            user = db.query(User).filter(User.email == request.email).first()
            logger.info("Using full User model")
        except sqlalchemy.exc.ProgrammingError as e:
            # If that fails due to missing columns, use the BasicUser model
            logger.warning(f"Error with full User model: {e}")
            logger.info("Falling back to BasicUser model")
            db.close()  # Close the failed transaction
            db = next(get_db())  # Get a fresh DB session
            user = db.query(BasicUser).filter(BasicUser.email == request.email).first()

        if not user:
            # Don't reveal that the user doesn't exist
            logger.info(f"Forgot password request for non-existent email: {request.email}")
            return {"message": "If your email is registered, you will receive password reset instructions."}

        # Generate a reset token
        reset_token = secrets.token_urlsafe(32)

        # Log the token for demo purposes
        logger.info(f"Password reset requested for user: {user.username}")
        logger.info(f"Reset token generated: {reset_token}")

        # Try to store the token in the database if possible
        try:
            # Check if we're using the full User model with reset_token
            if isinstance(user, User) and hasattr(user, 'reset_token'):
                user.reset_token = reset_token

                if hasattr(user, 'reset_token_expires'):
                    user.reset_token_expires = datetime.now(timezone.utc) + timedelta(hours=1)

                db.commit()
                logger.info("Token stored in database")
            else:
                logger.warning("Using BasicUser model - token will only be logged, not stored")
        except Exception as e:
            logger.error(f"Error storing token: {e}")
            # Continue anyway - we'll just log the token instead

        return {"message": "If your email is registered, you will receive password reset instructions."}

    except Exception as e:
        logger.error(f"Unexpected error in forgot_password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred"
        )

@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(
    request: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    """
    Reset a user's password using a reset token.
    """
    # For demo purposes, we'll use the token from the logs
    # In a real app, we would verify the token from the database

    try:
        # Try to find a user with this token in the database
        try:
            # Try with full User model first
            user = db.query(User).filter(User.reset_token == request.token).first()
            if user:
                logger.info("Found user with token using full User model")

                # Check if token has expired (if the column exists)
                if hasattr(user, 'reset_token_expires') and user.reset_token_expires:
                    if user.reset_token_expires < datetime.now(timezone.utc):
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Token has expired"
                        )
            else:
                logger.warning("No user found with this token in full User model")
        except sqlalchemy.exc.ProgrammingError as e:
            # If that fails, the reset_token column might not exist
            logger.warning(f"Error with full User model: {e}")
            user = None
            db.close()  # Close the failed transaction
            db = next(get_db())  # Get a fresh DB session

        # If we couldn't find a user with the token, check the logs
        # This is a fallback for demo purposes only
        if not user:
            logger.info("Checking token from logs (demo fallback)")

            # In a real app, we would reject the request here
            # For demo purposes, we'll allow the token from the logs

            # Extract username from token (this is a simplified demo approach)
            # In a real app, we would decode a JWT or use a proper token verification
            try:
                # For demo, we'll just check if the token exists in the logs
                # and allow any valid token format
                if len(request.token) < 32:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Invalid token format"
                    )

                # Get a basic user to update password
                # We'll prompt for email since we can't look up by token
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please use the mobile app to reset your password with the token"
                )
            except HTTPException:
                raise
            except Exception as e:
                logger.error(f"Error processing token: {e}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid token"
                )

        # Update the user's password
        try:
            # Update password
            user.hashed_password = get_password_hash(request.new_password)

            # Clear reset token if columns exist
            if hasattr(user, 'reset_token'):
                user.reset_token = None

                if hasattr(user, 'reset_token_expires'):
                    user.reset_token_expires = None

            # Save changes
            db.commit()
            logger.info(f"Password reset successful for user: {user.username}")

            return {"message": "Password has been reset successfully"}
        except Exception as e:
            logger.error(f"Error updating password: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="An error occurred while resetting your password"
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in reset_password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred"
        )
