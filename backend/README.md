# EnviroSense Backend

A FastAPI backend with JWT authentication and WebSocket functionality to receive sensor data from an ESP32 device.

## Features

- User authentication with JWT tokens
- Protected WebSocket endpoint for receiving sensor data
- Database storage for sensor data
- API endpoints for retrieving sensor data

## Installation

1. Clone the repository
2. Install dependencies:

```bash
cd backend
pip install -r requirements.txt
```

## Configuration

The application uses environment variables for configuration. Create a `.env` file in the backend directory with the following variables:

```
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
DATABASE_URL=postgresql://envirosensedb_user:rkNngiLgzhr6AQlLiywstBPl4gARlKZ5@dpg-d0kapsjuibrs739chbvg-a.singapore-postgres.render.com/envirosensedb
```

The application is configured to use the PostgreSQL database on Render for both local development and production.

## Running the Application

### Local Development

There are compatibility issues between SQLAlchemy 2.0.23 and Python 3.13. If you're using Python 3.13, you might encounter errors when running the application. Here are some options:

1. Use Python 3.10 or 3.11 (recommended for local development):
```bash
# Install Python 3.10 or 3.11
# Create a virtual environment
python -m venv venv
# Activate the virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
# Install dependencies
pip install -r requirements.txt
# Run the application
uvicorn app.main:app --reload
```

2. Use Docker (if available):
```bash
# Build the Docker image
docker build -t envirosense .
# Run the Docker container
docker run -p 8000:8000 envirosense
```

The application will be available at http://localhost:8000

### API Documentation

FastAPI automatically generates API documentation. Visit:
- http://localhost:8000/docs for Swagger UI
- http://localhost:8000/redoc for ReDoc

## API Endpoints

- `POST /api/v1/auth/register` - Register a new user
- `POST /api/v1/auth/token` - Login and get JWT token
- `GET /api/v1/auth/me` - Get current user info
- `WebSocket /api/v1/sensor/ws?token=your-jwt-token` - WebSocket endpoint for sensor data
- `GET /api/v1/sensor/data` - Get sensor data for current user

## Testing the Backend

### Running Automated Tests

```bash
# Install test dependencies
pip install -r requirements.txt

# Run all tests
pytest

# Run specific test files
pytest tests/test_auth.py
pytest tests/test_sensor.py
pytest tests/test_websocket.py

# Run tests with verbose output
pytest -v
```

### Getting a JWT Token

You can use the provided script to register a user and get a JWT token:

```bash
# Register a new user
python get_token.py register -u myusername -e myemail@example.com -p mypassword

# Get a JWT token
python get_token.py login -u myusername -p mypassword
```

### Testing WebSocket Connection

You can use the provided script to test the WebSocket connection:

```bash
# Get a token first
TOKEN=$(python get_token.py login -u myusername -p mypassword)

# Test WebSocket connection with simulated sensor data
python test_websocket.py -t $TOKEN
```

### Manual Testing with Swagger UI

1. Start the server: `uvicorn app.main:app --reload`
2. Open your browser and navigate to: `http://localhost:8000/docs`
3. Use the Swagger UI to test the endpoints:
   - Register a user via `/api/v1/auth/register`
   - Get a token via `/api/v1/auth/token`
   - Click the "Authorize" button and enter your token
   - Test other endpoints

## ESP32 Configuration

Update the ESP32 code with your JWT token:

```cpp
// JWT Token (get this from login endpoint)
const char* jwt_token = "your-jwt-token-here";  // Replace with your actual JWT token
```

## Deployment on Render

1. Push your code to a Git repository
2. Connect your repository to Render
3. Set up a Web Service with the following settings:
   - Root Directory: `backend`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn app.main:app --host=0.0.0.0 --port=10000`
   - Environment Variables: Set the same variables as in the `.env` file

Note: Render uses Python 3.7 by default, which should be compatible with all the dependencies in this project. If you want to use a different Python version, you can specify it in the Environment Variables section:
```
PYTHON_VERSION=3.10
```

## Git Workflow

### Using the Batch File

The simplest way to commit and push your changes is to use the provided batch file:

```bash
# From the project root or backend directory
commit "Your commit message"
```

### Using the Python Script

For more advanced Git operations, you can use the Python script:

```bash
# Check Git status
python git_push.py status

# Add specific files
python git_push.py add file1.py file2.py

# Commit changes
python git_push.py commit -m "Your commit message" -a

# Push changes
python git_push.py push

# Pull changes
python git_push.py pull

# Add, commit, and push in one command
python git_push.py all -m "Your commit message"
```
