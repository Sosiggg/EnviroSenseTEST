import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.db.database import Base, get_db
from app.core.auth import get_password_hash

# Create an in-memory SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Override the get_db dependency
def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    # Create the database tables
    Base.metadata.create_all(bind=engine)
    
    # Use the TestClient
    with TestClient(app) as c:
        yield c
    
    # Drop the database tables
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_db():
    # Create the database tables
    Base.metadata.create_all(bind=engine)
    
    # Create a test session
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
    
    # Drop the database tables
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_user(test_db):
    """Create a test user and return the user data"""
    from app.models.user import User
    
    # Create a test user
    hashed_password = get_password_hash("testpassword")
    db_user = User(
        username="testuser",
        email="test@example.com",
        hashed_password=hashed_password,
        is_active=True
    )
    test_db.add(db_user)
    test_db.commit()
    test_db.refresh(db_user)
    
    return {
        "id": db_user.id,
        "username": db_user.username,
        "email": db_user.email,
        "password": "testpassword"  # Plain password for testing
    }

@pytest.fixture
def token(client, test_user):
    """Get a JWT token for the test user"""
    response = client.post(
        "/api/v1/auth/token",
        data={
            "username": test_user["username"],
            "password": test_user["password"]
        }
    )
    return response.json()["access_token"]
