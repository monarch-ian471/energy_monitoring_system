#!/usr/bin/env python3
"""
FastAPI server runner for Energy Monitoring System
"""
import uvicorn
from api import app

if __name__ == "__main__":
    print("Starting Energy Monitoring System API...")
    print("API will be available at: http://localhost:8000")
    print("API documentation at: http://localhost:8000/docs")
    print("Press Ctrl+C to stop the server")
    
    uvicorn.run(
        "api:app",
        host="0.0.0.0",  # Allow external connections
        port=8000,
        reload=True,     # Auto-reload on code changes
        log_level="info"
    ) 