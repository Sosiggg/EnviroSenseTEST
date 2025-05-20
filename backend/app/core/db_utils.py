"""
Database utility functions for safely working with the database.
These functions handle missing columns gracefully.
"""
import logging
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError, ProgrammingError

logger = logging.getLogger(__name__)

def get_user_by_email(db: Session, email: str):
    """
    Get a user by email using raw SQL to avoid ORM issues with missing columns.
    This function only selects columns that definitely exist in the database.
    """
    try:
        # Use raw SQL to only select columns that definitely exist
        query = text("SELECT id, username, email, hashed_password, is_active FROM users WHERE email = :email LIMIT 1")

        result = db.execute(query, {"email": email})
        user_data = result.fetchone()

        if not user_data:
            return None

        # Convert to dictionary for easier access
        user_dict = {
            "id": user_data[0],
            "username": user_data[1],
            "email": user_data[2],
            "hashed_password": user_data[3],
            "is_active": user_data[4]
        }

        return user_dict
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_user_by_email: {e}")
        return None

def get_user_by_username(db: Session, username: str):
    """
    Get a user by username using raw SQL to avoid ORM issues with missing columns.
    This function only selects columns that definitely exist in the database.
    """
    try:
        # Use raw SQL to only select columns that definitely exist
        query = text("SELECT id, username, email, hashed_password, is_active FROM users WHERE username = :username LIMIT 1")

        result = db.execute(query, {"username": username})
        user_data = result.fetchone()

        if not user_data:
            return None

        # Convert to dictionary for easier access
        user_dict = {
            "id": user_data[0],
            "username": user_data[1],
            "email": user_data[2],
            "hashed_password": user_data[3],
            "is_active": user_data[4]
        }

        return user_dict
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_user_by_username: {e}")
        return None

def update_user_password(db: Session, user_id: int, hashed_password: str):
    """
    Update a user's password using raw SQL to avoid ORM issues with missing columns.
    """
    try:
        query = text("UPDATE users SET hashed_password = :hashed_password WHERE id = :user_id")

        db.execute(query, {"user_id": user_id, "hashed_password": hashed_password})
        db.commit()
        return True
    except SQLAlchemyError as e:
        logger.error(f"Database error in update_user_password: {e}")
        db.rollback()
        return False

def check_column_exists(db: Session, table: str, column: str):
    """
    Check if a column exists in a table.
    """
    try:
        query = text("SELECT column_name FROM information_schema.columns WHERE table_name = :table AND column_name = :column")

        result = db.execute(query, {"table": table, "column": column})
        return result.fetchone() is not None
    except SQLAlchemyError as e:
        logger.error(f"Database error in check_column_exists: {e}")
        return False

def store_reset_token(db: Session, user_id: int, token: str, expires_at=None):
    """
    Store a password reset token for a user if the columns exist.
    """
    try:
        # Check if reset_token column exists
        if not check_column_exists(db, "users", "reset_token"):
            logger.warning("reset_token column does not exist in users table")
            return False

        # Build the query based on which columns exist
        if expires_at and check_column_exists(db, "users", "reset_token_expires"):
            query = text("UPDATE users SET reset_token = :token, reset_token_expires = :expires_at WHERE id = :user_id")
            params = {"user_id": user_id, "token": token, "expires_at": expires_at}
        else:
            query = text("UPDATE users SET reset_token = :token WHERE id = :user_id")
            params = {"user_id": user_id, "token": token}

        db.execute(query, params)
        db.commit()
        return True
    except SQLAlchemyError as e:
        logger.error(f"Database error in store_reset_token: {e}")
        db.rollback()
        return False

def get_user_by_reset_token(db: Session, token: str):
    """
    Get a user by reset token if the column exists.
    """
    try:
        # Check if reset_token column exists
        if not check_column_exists(db, "users", "reset_token"):
            logger.warning("reset_token column does not exist in users table")
            return None

        # Use raw SQL to only select columns that definitely exist
        query = text("SELECT id, username, email, hashed_password, is_active FROM users WHERE reset_token = :token LIMIT 1")

        result = db.execute(query, {"token": token})
        user_data = result.fetchone()

        if not user_data:
            return None

        # Convert to dictionary for easier access
        user_dict = {
            "id": user_data[0],
            "username": user_data[1],
            "email": user_data[2],
            "hashed_password": user_data[3],
            "is_active": user_data[4]
        }

        return user_dict
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_user_by_reset_token: {e}")
        return None
