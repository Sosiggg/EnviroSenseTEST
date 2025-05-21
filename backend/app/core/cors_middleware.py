from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response, JSONResponse
import logging
import json
from typing import Callable

logger = logging.getLogger(__name__)

class CORSMiddleware(BaseHTTPMiddleware):
    """
    Custom middleware to ensure CORS headers are added to all responses,
    including error responses.
    """
    
    async def dispatch(self, request: Request, call_next: Callable):
        # Get the client's origin or use wildcard
        origin = request.headers.get("origin", "*")
        
        # Handle preflight requests
        if request.method == "OPTIONS":
            return self._handle_preflight(origin)
        
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
            error_response = JSONResponse(
                content={"detail": f"Internal server error: {str(e)}"},
                status_code=500
            )
            
            # Add CORS headers to the response
            error_response.headers["Access-Control-Allow-Origin"] = origin
            error_response.headers["Access-Control-Allow-Credentials"] = "true"
            error_response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
            error_response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, Accept, Origin, X-Requested-With"
            
            return error_response
    
    def _handle_preflight(self, origin: str) -> Response:
        """
        Handle preflight requests by returning a response with appropriate CORS headers.
        """
        response = Response(
            content="",
            status_code=200
        )
        
        # Add CORS headers to the response
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, Accept, Origin, X-Requested-With"
        response.headers["Access-Control-Max-Age"] = "86400"  # Cache preflight requests for 24 hours
        
        return response
