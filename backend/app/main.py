from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints.hello import router as hello_router

app = FastAPI()

origins = [
    "http://localhost:3000",  
    "http://localhost:5173",  
    "http://localhost:8081",  
    "http://127.0.0.1:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the hello endpoint
app.include_router(hello_router, prefix="/api/v1/hello")
