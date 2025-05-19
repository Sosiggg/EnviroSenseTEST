from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints.hello import router as hello_router
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.sensor import router as sensor_router
from app.db.init_db import create_tables

app = FastAPI(title="EnviroSense API")

origins = [
    "http://localhost:3000",
    "http://localhost:5173",
    "http://localhost:8081",
    "http://localhost:8000",
    "http://localhost:9101",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:9101",
    "http://127.0.0.1:*",
    "http://localhost:*",
    "https://envirosense-2khv.onrender.com",
    "https://envirosense-2khv.onrender.com:443",
    # Allow all origins during development
    "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables on startup
@app.on_event("startup")
async def startup_event():
    create_tables()

# Include routers
app.include_router(hello_router, prefix="/api/v1/hello")
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(sensor_router, prefix="/api/v1/sensor", tags=["Sensor Data"])
