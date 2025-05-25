from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from app.api.v1.endpoints.hello import router as hello_router
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.sensor import router as sensor_router
from app.db.init_db import create_tables
from app.core.cors_middleware import CORSMiddleware as CustomCORSMiddleware

from contextlib import asynccontextmanager

# Define lifespan context manager (new recommended approach)
@asynccontextmanager
async def lifespan(_: FastAPI):
    # Startup: create database tables
    print("Creating database tables...")
    create_tables()
    yield
    # Shutdown: cleanup resources if needed
    print("Shutting down application...")

# Import custom response class
from app.core.responses import CORSJSONResponse

# Create FastAPI app with lifespan
app = FastAPI(
    title="EnviroSense API",
    description="API for EnviroSense IoT platform",
    version="1.0.0",
    lifespan=lifespan,
    default_response_class=CORSJSONResponse  # Use our custom response class
)

# Define allowed origins based on environment
# In production, you should list specific origins instead of using "*"
# Get environment variable to determine if we're in development or production
import os
is_development = os.getenv("ENVIRONMENT", "development").lower() == "development"

# Define specific origins for different environments
origins = [
    # Local development origins
    "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:3002",
    "http://localhost:3003",
    "http://localhost:5173",
    "http://localhost:8081",
    "http://localhost:8000",
    "http://localhost:9101",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3001",
    "http://127.0.0.1:3002",
    "http://127.0.0.1:3003",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:9101",
    # Production origins
    "https://envirosense-2khv.onrender.com",
    "https://envirosense-2khv.onrender.com:443",
    # Netlify domains (including preview deployments)
    "https://envirosense-web.netlify.app",
    "https://envirosense-web-*.netlify.app",
    # Allow all Netlify preview deployments
    "https://*.netlify.app",
]

# Always allow all origins for now to fix CORS issues
# This is a temporary solution - in a production environment, you should use specific origins
# Using "*" instead of specific origins to ensure all requests are accepted
origins = ["*"]

# Add our custom CORS middleware first to ensure it catches all responses
app.add_middleware(CustomCORSMiddleware)

# Add FastAPI's built-in CORS middleware as a backup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_origin_regex=r"https://.*\.netlify\.app",  # Allow all Netlify domains
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=[
        "Content-Type",
        "Authorization",
        "Accept",
        "Origin",
        "X-Requested-With",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
    ],
    expose_headers=[
        "Content-Length",
        "Content-Type",
        "X-Total-Count",
    ],
    max_age=86400  # Cache preflight requests for 24 hours
)

# Lifespan context manager is defined at the top of the file

# Add custom exception handlers to ensure CORS headers are included in all responses
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import traceback
import logging

# Handle all unhandled exceptions
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Log the error
    logging.error(f"Unhandled exception: {str(exc)}")
    logging.error(traceback.format_exc())

    # Get the client's origin
    origin = request.headers.get("origin", "*")

    # Return a JSON response with CORS headers
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error. The team has been notified."},
        headers={
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
        }
    )

# Handle HTTP exceptions (4xx, 5xx)
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    # Get the client's origin
    origin = request.headers.get("origin", "*")

    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers={
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
        }
    )

# Handle validation errors
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Get the client's origin
    origin = request.headers.get("origin", "*")

    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors()},
        headers={
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
        }
    )

# Include routers
app.include_router(hello_router, prefix="/api/v1/hello")
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(sensor_router, prefix="/api/v1/sensor", tags=["Sensor Data"])

# Root endpoint for API documentation
@app.get("/", response_class=CORSJSONResponse)
async def root():
    """
    EnviroSense API Documentation

    Welcome to the EnviroSense IoT Platform API!
    This endpoint provides a comprehensive list of all available API endpoints.
    """
    return {
        "message": "Welcome to EnviroSense API",
        "version": "1.0.0",
        "description": "IoT Environmental Monitoring Platform",
        "documentation": {
            "swagger_ui": "/docs",
            "redoc": "/redoc"
        },
        "endpoints": {
            "authentication": {
                "description": "User authentication and account management",
                "base_path": "/api/v1/auth",
                "endpoints": [
                    {
                        "method": "POST",
                        "path": "/api/v1/auth/register",
                        "description": "Register a new user account",
                        "parameters": "username, email, password"
                    },
                    {
                        "method": "POST",
                        "path": "/api/v1/auth/token",
                        "description": "Login and obtain JWT access token",
                        "parameters": "username, password"
                    },
                    {
                        "method": "GET",
                        "path": "/api/v1/auth/me",
                        "description": "Get current authenticated user information",
                        "auth_required": True
                    },
                    {
                        "method": "POST",
                        "path": "/api/v1/auth/email-token",
                        "description": "Generate and send authentication token to user's email",
                        "parameters": "email"
                    },
                    {
                        "method": "POST",
                        "path": "/api/v1/auth/forgot-password",
                        "description": "Initiate password reset process",
                        "parameters": "email"
                    },
                    {
                        "method": "POST",
                        "path": "/api/v1/auth/reset-password",
                        "description": "Reset password using token",
                        "parameters": "token, new_password"
                    },
                    {
                        "method": "PUT",
                        "path": "/api/v1/auth/change-password",
                        "description": "Change password for authenticated user",
                        "parameters": "current_password, new_password",
                        "auth_required": True
                    }
                ]
            },
            "sensor_data": {
                "description": "Sensor data management and real-time monitoring",
                "base_path": "/api/v1/sensor",
                "endpoints": [
                    {
                        "method": "WebSocket",
                        "path": "/api/v1/sensor/ws",
                        "description": "Real-time sensor data WebSocket connection",
                        "auth_options": ["?token=jwt-token", "?email=user@example.com"],
                        "data_format": "JSON with temperature, humidity, obstacle status",
                        "features": ["Real-time data streaming", "Ping/pong health checks"]
                    },
                    {
                        "method": "GET",
                        "path": "/api/v1/sensor/data",
                        "description": "Get paginated sensor data with optional filtering",
                        "parameters": "start_date, end_date, page, page_size",
                        "auth_required": True
                    },
                    {
                        "method": "GET",
                        "path": "/api/v1/sensor/data/latest",
                        "description": "Get the latest sensor reading for authenticated user",
                        "returns": "Most recent temperature, humidity, obstacle status",
                        "auth_required": True
                    },
                    {
                        "method": "GET",
                        "path": "/api/v1/sensor/data/check",
                        "description": "Check sensor data availability and diagnostics",
                        "returns": "Record count and date range of available data",
                        "auth_required": True
                    }
                ]
            },
            "utilities": {
                "description": "Utility and health check endpoints",
                "endpoints": [
                    {
                        "method": "GET",
                        "path": "/api/v1/hello/",
                        "description": "Simple health check endpoint",
                        "returns": "Greeting message"
                    },
                    {
                        "method": "GET",
                        "path": "/",
                        "description": "API documentation (this endpoint)",
                        "returns": "Complete API endpoint listing"
                    }
                ]
            }
        },
        "authentication": {
            "type": "JWT Bearer Token",
            "header": "Authorization: Bearer <your-jwt-token>",
            "how_to_get_token": "POST /api/v1/auth/token with username and password"
        },
        "data_formats": {
            "sensor_data": {
                "temperature": "float (Celsius)",
                "humidity": "float (percentage)",
                "obstacle": "boolean (true/false)"
            },
            "datetime": "ISO 8601 format (YYYY-MM-DDTHH:MM:SS)"
        },
        "websocket_usage": {
            "connection": "wss://envirosense-2khv.onrender.com/api/v1/sensor/ws",
            "authentication": [
                "Query parameter: ?token=your-jwt-token",
                "Query parameter: ?email=your-email@example.com"
            ],
            "message_format": {
                "sensor_data": {
                    "temperature": 25.5,
                    "humidity": 60.0,
                    "obstacle": False
                },
                "ping": "ping",
                "pong": "pong"
            }
        },
        "example_usage": {
            "register": {
                "url": "POST /api/v1/auth/register",
                "body": {
                    "username": "john_doe",
                    "email": "john@example.com",
                    "password": "secure_password123"
                }
            },
            "login": {
                "url": "POST /api/v1/auth/token",
                "body": {
                    "username": "john_doe",
                    "password": "secure_password123"
                }
            },
            "get_sensor_data": {
                "url": "GET /api/v1/sensor/data?page=1&page_size=10",
                "headers": {
                    "Authorization": "Bearer your-jwt-token"
                }
            }
        },
        "status": "✅ API is running",
        "environment": "Production",
        "contact": {
            "support": "For technical support, please check the documentation",
            "github": "https://github.com/your-repo/envirosense"
        }
    }

# HTML documentation endpoint for better browser viewing
@app.get("/docs-html", response_class=HTMLResponse)
async def docs_html():
    """
    HTML version of API documentation for better browser viewing
    """
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EnviroSense API Documentation</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                margin: 0;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                max-width: 1200px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
            }
            h1 {
                color: #2c3e50;
                text-align: center;
                border-bottom: 3px solid #3498db;
                padding-bottom: 10px;
            }
            h2 {
                color: #34495e;
                border-left: 4px solid #3498db;
                padding-left: 15px;
                margin-top: 30px;
            }
            h3 {
                color: #2980b9;
            }
            .endpoint {
                background: #f8f9fa;
                border: 1px solid #e9ecef;
                border-radius: 5px;
                padding: 15px;
                margin: 10px 0;
            }
            .method {
                display: inline-block;
                padding: 4px 8px;
                border-radius: 4px;
                font-weight: bold;
                font-size: 12px;
                margin-right: 10px;
            }
            .get { background: #28a745; color: white; }
            .post { background: #007bff; color: white; }
            .put { background: #ffc107; color: black; }
            .delete { background: #dc3545; color: white; }
            .websocket { background: #6f42c1; color: white; }
            .path {
                font-family: 'Courier New', monospace;
                background: #e9ecef;
                padding: 2px 6px;
                border-radius: 3px;
                font-size: 14px;
            }
            .auth-required {
                color: #dc3545;
                font-size: 12px;
                font-weight: bold;
            }
            .status {
                text-align: center;
                padding: 20px;
                background: #d4edda;
                border: 1px solid #c3e6cb;
                border-radius: 5px;
                color: #155724;
                font-size: 18px;
                font-weight: bold;
            }
            .quick-links {
                text-align: center;
                margin: 20px 0;
            }
            .quick-links a {
                display: inline-block;
                margin: 0 10px;
                padding: 10px 20px;
                background: #3498db;
                color: white;
                text-decoration: none;
                border-radius: 5px;
                transition: background 0.3s;
            }
            .quick-links a:hover {
                background: #2980b9;
            }
            .example {
                background: #f1f3f4;
                border-left: 4px solid #3498db;
                padding: 15px;
                margin: 10px 0;
                font-family: 'Courier New', monospace;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🌱 EnviroSense API Documentation</h1>

            <div class="status">
                ✅ API is running - Production Environment
            </div>

            <div class="quick-links">
                <a href="/docs" target="_blank">Swagger UI</a>
                <a href="/redoc" target="_blank">ReDoc</a>
                <a href="/" target="_blank">JSON API</a>
            </div>

            <h2>🔐 Authentication Endpoints</h2>
            <p>User authentication and account management</p>

            <div class="endpoint">
                <span class="method post">POST</span>
                <span class="path">/api/v1/auth/register</span>
                <p><strong>Register a new user account</strong></p>
                <p>Parameters: username, email, password</p>
            </div>

            <div class="endpoint">
                <span class="method post">POST</span>
                <span class="path">/api/v1/auth/token</span>
                <p><strong>Login and obtain JWT access token</strong></p>
                <p>Parameters: username, password</p>
            </div>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/api/v1/auth/me</span>
                <span class="auth-required">🔒 Auth Required</span>
                <p><strong>Get current authenticated user information</strong></p>
            </div>

            <div class="endpoint">
                <span class="method post">POST</span>
                <span class="path">/api/v1/auth/email-token</span>
                <p><strong>Generate and send authentication token to user's email</strong></p>
                <p>Parameters: email</p>
            </div>

            <div class="endpoint">
                <span class="method post">POST</span>
                <span class="path">/api/v1/auth/forgot-password</span>
                <p><strong>Initiate password reset process</strong></p>
                <p>Parameters: email</p>
            </div>

            <div class="endpoint">
                <span class="method post">POST</span>
                <span class="path">/api/v1/auth/reset-password</span>
                <p><strong>Reset password using token</strong></p>
                <p>Parameters: token, new_password</p>
            </div>

            <div class="endpoint">
                <span class="method put">PUT</span>
                <span class="path">/api/v1/auth/change-password</span>
                <span class="auth-required">🔒 Auth Required</span>
                <p><strong>Change password for authenticated user</strong></p>
                <p>Parameters: current_password, new_password</p>
            </div>

            <h2>📊 Sensor Data Endpoints</h2>
            <p>Sensor data management and real-time monitoring</p>

            <div class="endpoint">
                <span class="method websocket">WebSocket</span>
                <span class="path">/api/v1/sensor/ws</span>
                <p><strong>Real-time sensor data WebSocket connection</strong></p>
                <p>Authentication: ?token=jwt-token OR ?email=user@example.com</p>
                <p>Data format: JSON with temperature, humidity, obstacle status</p>
                <p>Features: Real-time data streaming, Ping/pong health checks</p>
            </div>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/api/v1/sensor/data</span>
                <span class="auth-required">🔒 Auth Required</span>
                <p><strong>Get paginated sensor data with optional filtering</strong></p>
                <p>Parameters: start_date, end_date, page, page_size</p>
            </div>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/api/v1/sensor/data/latest</span>
                <span class="auth-required">🔒 Auth Required</span>
                <p><strong>Get the latest sensor reading for authenticated user</strong></p>
                <p>Returns: Most recent temperature, humidity, obstacle status</p>
            </div>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/api/v1/sensor/data/check</span>
                <span class="auth-required">🔒 Auth Required</span>
                <p><strong>Check sensor data availability and diagnostics</strong></p>
                <p>Returns: Record count and date range of available data</p>
            </div>

            <h2>🛠️ Utility Endpoints</h2>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/api/v1/hello/</span>
                <p><strong>Simple health check endpoint</strong></p>
                <p>Returns: Greeting message</p>
            </div>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/</span>
                <p><strong>API documentation (JSON format)</strong></p>
                <p>Returns: Complete API endpoint listing in JSON</p>
            </div>

            <div class="endpoint">
                <span class="method get">GET</span>
                <span class="path">/docs-html</span>
                <p><strong>API documentation (HTML format)</strong></p>
                <p>Returns: This beautiful documentation page</p>
            </div>

            <h2>🔑 Authentication Guide</h2>
            <div class="example">
                <strong>1. Register a new user:</strong><br>
                POST /api/v1/auth/register<br>
                {<br>
                &nbsp;&nbsp;"username": "john_doe",<br>
                &nbsp;&nbsp;"email": "john@example.com",<br>
                &nbsp;&nbsp;"password": "secure_password123"<br>
                }<br><br>

                <strong>2. Login to get JWT token:</strong><br>
                POST /api/v1/auth/token<br>
                {<br>
                &nbsp;&nbsp;"username": "john_doe",<br>
                &nbsp;&nbsp;"password": "secure_password123"<br>
                }<br><br>

                <strong>3. Use token in headers:</strong><br>
                Authorization: Bearer your-jwt-token
            </div>

            <h2>🌐 WebSocket Connection</h2>
            <div class="example">
                <strong>Connection URL:</strong><br>
                wss://envirosense-2khv.onrender.com/api/v1/sensor/ws?token=your-jwt-token<br><br>

                <strong>Send sensor data:</strong><br>
                {<br>
                &nbsp;&nbsp;"temperature": 25.5,<br>
                &nbsp;&nbsp;"humidity": 60.0,<br>
                &nbsp;&nbsp;"obstacle": false<br>
                }
            </div>

            <h2>📱 Mobile App Integration</h2>
            <p>This API is designed to work with the EnviroSense Flutter mobile application. The mobile app provides:</p>
            <ul>
                <li>Real-time sensor data visualization</li>
                <li>Historical data charts and analytics</li>
                <li>User authentication and profile management</li>
                <li>Push notifications for sensor alerts</li>
                <li>Offline data caching</li>
            </ul>

            <div style="text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee;">
                <p><strong>EnviroSense IoT Platform v1.0.0</strong></p>
                <p>Environmental Monitoring Made Simple</p>
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)
