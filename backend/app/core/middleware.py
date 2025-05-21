from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import logging

logger = logging.getLogger(__name__)

class CORSMiddleware(BaseHTTPMiddleware):
    """
    Custom middleware to ensure CORS headers are added to all responses,
    including error responses.
    """
    
    async def dispatch(self, request: Request, call_next):
        # Get the client's origin
        origin = request.headers.get("origin", "*")
        
        # Process the request and get the response
        try:
            response = await call_next(request)
            
            # Add CORS headers to the response
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, Accept, Origin, X-Requested-With"
            
            return response
        except Exception as e:
            # Log the error
            logger.error(f"Error in CORS middleware: {str(e)}")
            
            # Create a new response with CORS headers
            response = Response(
                content={"detail": "Internal server error"},
                status_code=500,
                media_type="application/json"
            )
            
            # Add CORS headers to the response
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, Accept, Origin, X-Requested-With"
            
            return response
