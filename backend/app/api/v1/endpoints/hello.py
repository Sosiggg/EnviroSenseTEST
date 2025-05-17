from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def say_hello():
    return {"message": "Hello from API v1!"}
