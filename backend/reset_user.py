from app.core.auth import get_password_hash
from app.db.database import get_db, engine
from app.models.user import User
from sqlalchemy.orm import Session
import sys

def reset_password(username, new_password):
    """Reset a user's password"""
    # Hash the new password
    hashed_password = get_password_hash(new_password)
    
    # Create a session
    db = Session(engine)
    
    try:
        # Find the user
        user = db.query(User).filter(User.username == username).first()
        
        if user:
            # Update the password
            user.hashed_password = hashed_password
            db.commit()
            print(f"Password reset successful for user {username} (ID: {user.id})")
        else:
            print(f"User {username} not found")
            
            # List all users
            users = db.query(User).all()
            print("\nAvailable users:")
            for u in users:
                print(f"ID: {u.id}, Username: {u.username}, Email: {u.email}")
    finally:
        db.close()

def reset_username(old_username, new_username):
    """Reset a user's username"""
    # Create a session
    db = Session(engine)
    
    try:
        # Find the user
        user = db.query(User).filter(User.username == old_username).first()
        
        if user:
            # Update the username
            user.username = new_username
            db.commit()
            print(f"Username changed from {old_username} to {new_username} (ID: {user.id})")
        else:
            print(f"User {old_username} not found")
            
            # List all users
            users = db.query(User).all()
            print("\nAvailable users:")
            for u in users:
                print(f"ID: {u.id}, Username: {u.username}, Email: {u.email}")
    finally:
        db.close()

def list_users():
    """List all users"""
    # Create a session
    db = Session(engine)
    
    try:
        # Get all users
        users = db.query(User).all()
        
        print("Users in the database:")
        print("ID | Username | Email | Active")
        print("-" * 50)
        for user in users:
            print(f"{user.id} | {user.username} | {user.email} | {user.is_active}")
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python reset_user.py list")
        print("  python reset_user.py reset_password <username> <new_password>")
        print("  python reset_user.py reset_username <old_username> <new_username>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list":
        list_users()
    elif command == "reset_password" and len(sys.argv) == 4:
        reset_password(sys.argv[2], sys.argv[3])
    elif command == "reset_username" and len(sys.argv) == 4:
        reset_username(sys.argv[2], sys.argv[3])
    else:
        print("Invalid command or missing arguments")
        print("Usage:")
        print("  python reset_user.py list")
        print("  python reset_user.py reset_password <username> <new_password>")
        print("  python reset_user.py reset_username <old_username> <new_username>")
