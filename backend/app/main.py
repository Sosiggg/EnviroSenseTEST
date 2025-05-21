from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints.hello import router as hello_router
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.sensor import router as sensor_router
from app.db.init_db import create_tables

app = FastAPI(title="EnviroSense API")

# Define allowed origins based on environment
# In production, you should list specific origins instead of using "*"
# Get environment variable to determine if we're in development or production
import os
is_development = os.getenv("ENVIRONMENT", "development").lower() == "development"

# Define specific origins for different environments
web_origins = [
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
    "https://envirosense-web.netlify.app",
]

# In development, allow all origins for easier testing
origins = ["*"] if is_development else web_origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
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
        "Access-Control-Allow-Origin",
    ],
    expose_headers=[
        "Content-Length",
        "Content-Type",
        "X-Total-Count"
    ],
    max_age=600  # Cache preflight requests for 10 minutes
)

# Create database tables on startup
@app.on_event("startup")
async def startup_event():
    create_tables()

# Include routers
app.include_router(hello_router, prefix="/api/v1/hello")
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(sensor_router, prefix="/api/v1/sensor", tags=["Sensor Data"])
