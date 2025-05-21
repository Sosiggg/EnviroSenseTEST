from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
