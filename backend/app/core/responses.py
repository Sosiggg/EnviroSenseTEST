from fastapi.responses import JSONResponse
from starlette.background import BackgroundTask
from typing import Any, Dict, List, Optional, Union

class CORSJSONResponse(JSONResponse):
    """
    Custom JSONResponse that automatically adds CORS headers to all responses.
    """
    
    def __init__(
        self,
        content: Any,
        status_code: int = 200,
        headers: Optional[Dict[str, str]] = None,
        media_type: Optional[str] = None,
        background: Optional[BackgroundTask] = None,
    ) -> None:
        if headers is None:
            headers = {}
        
        # Add CORS headers
        headers.update({
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin, X-Requested-With",
        })
        
        super().__init__(content, status_code, headers, media_type, background)
