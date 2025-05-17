import uvicorn
import os
import sys

# Add the current directory to the Python path
sys.path.insert(0, os.path.abspath("."))

if __name__ == "__main__":
    print("Starting FastAPI application...")
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
