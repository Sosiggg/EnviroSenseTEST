from app.main import app
import uvicorn

if __name__ == "__main__":
    print("Starting FastAPI application...")
    uvicorn.run(app, host="127.0.0.1", port=8000)
