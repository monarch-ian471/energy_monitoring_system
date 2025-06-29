from fastapi import FastAPI, HTTPException, Query, status
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
import os
from pathlib import Path
import json
from datetime import datetime, timedelta
import re

app = FastAPI(
    title="Energy Monitoring System API",
    description="API for monitoring energy consumption data",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Get the directory where this script is located
SCRIPT_DIR = Path(__file__).parent.absolute()
DB_PATH = SCRIPT_DIR / "energy_data.db"

# Log file paths
API_LOG_PATH = SCRIPT_DIR / "api.log"
ENERGY_MONITOR_LOG_PATH = SCRIPT_DIR / "energy_monitor.log"

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Energy Monitoring System API",
        "version": "1.0.0",
        "endpoints": {
            "current_energy": "/energy",
            "energy_history": "/energy/history",
            "logs": "/logs/energy-monitor",
            "api_logs": "/logs/api",
            "health": "/health"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check if database exists and is accessible
        db_accessible = DB_PATH.exists()
        
        # Check if log files exist
        energy_log_exists = ENERGY_MONITOR_LOG_PATH.exists()
        api_log_exists = API_LOG_PATH.exists()
        
        return {
            "status": "healthy",
            "database": "accessible" if db_accessible else "not_found",
            "energy_monitor_log": "exists" if energy_log_exists else "not_found",
            "api_log": "exists" if api_log_exists else "not_found",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Health check failed: {str(e)}"
        )

@app.get("/energy")
async def get_energy():
    try:
        conn = sqlite3.connect(str(DB_PATH))
        c = conn.cursor()
        c.execute("SELECT timestamp, watts FROM usage ORDER BY timestamp DESC LIMIT 1")
        data = c.fetchone()
        conn.close()
        if data:
            return {"timestamp": data[0], "watts": data[1]}
        return {"error": "No data available"}
    except Exception as e:
        return {"error": f"Database error: {str(e)}"}

@app.get("/energy/history")
async def get_history():
    try:
        conn = sqlite3.connect(str(DB_PATH))
        c = conn.cursor()
        c.execute("SELECT timestamp, watts FROM usage ORDER BY timestamp DESC LIMIT 24")
        data = c.fetchall()
        conn.close()
        # Return in the format expected by Flutter app
        return {
            "data": [{"timestamp": row[0], "watts": row[1]} for row in data]
        }
    except Exception as e:
        return {"error": f"Database error: {str(e)}"}

@app.get("/logs/energy-monitor")
async def get_energy_monitor_logs():
    """Get energy monitor log data for historical analysis"""
    try:
        if not ENERGY_MONITOR_LOG_PATH.exists():
            return {"error": "Energy monitor log file not found"}
        
        log_data = []
        with open(ENERGY_MONITOR_LOG_PATH, 'r') as f:
            for line in f:
                # Parse log line for energy data
                # Expected format: "Time: 2024-01-15 14:30:25, Power: 43.50 W"
                match = re.search(r'Time: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}), Power: ([\d.]+) W', line)
                if match:
                    timestamp = match.group(1)
                    watts = float(match.group(2))
                    log_data.append({
                        "timestamp": timestamp,
                        "watts": watts,
                        "source": "energy_monitor"
                    })
        
        return {
            "data": log_data,
            "total_records": len(log_data),
            "file_size": ENERGY_MONITOR_LOG_PATH.stat().st_size
        }
    except Exception as e:
        return {"error": f"Error reading energy monitor log: {str(e)}"}

@app.get("/logs/api")
async def get_api_logs():
    """Get API log data for system monitoring"""
    try:
        if not API_LOG_PATH.exists():
            return {"error": "API log file not found"}
        
        log_data = []
        with open(API_LOG_PATH, 'r') as f:
            for line in f:
                # Parse API log lines for request data
                # Look for timestamp patterns
                timestamp_match = re.search(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', line)
                if timestamp_match:
                    timestamp = timestamp_match.group(1)
                    log_data.append({
                        "timestamp": timestamp,
                        "message": line.strip(),
                        "source": "api"
                    })
        
        return {
            "data": log_data,
            "total_records": len(log_data),
            "file_size": API_LOG_PATH.stat().st_size
        }
    except Exception as e:
        return {"error": f"Error reading API log: {str(e)}"}

@app.get("/logs/download/energy-monitor")
async def download_energy_monitor_log():
    """Download energy monitor log file"""
    if not ENERGY_MONITOR_LOG_PATH.exists():
        raise HTTPException(status_code=404, detail="Energy monitor log file not found")
    
    return FileResponse(
        path=str(ENERGY_MONITOR_LOG_PATH),
        filename="energy_monitor.log",
        media_type="text/plain"
    )

@app.get("/logs/download/api")
async def download_api_log():
    """Download API log file"""
    if not API_LOG_PATH.exists():
        raise HTTPException(status_code=404, detail="API log file not found")
    
    return FileResponse(
        path=str(API_LOG_PATH),
        filename="api.log",
        media_type="text/plain"
    )

@app.get("/logs/summary")
async def get_logs_summary():
    """Get summary statistics from both log files"""
    try:
        summary = {
            "energy_monitor": {
                "exists": ENERGY_MONITOR_LOG_PATH.exists(),
                "size": ENERGY_MONITOR_LOG_PATH.stat().st_size if ENERGY_MONITOR_LOG_PATH.exists() else 0,
                "records": 0
            },
            "api": {
                "exists": API_LOG_PATH.exists(),
                "size": API_LOG_PATH.stat().st_size if API_LOG_PATH.exists() else 0,
                "records": 0
            }
        }
        
        # Count energy monitor records
        if ENERGY_MONITOR_LOG_PATH.exists():
            with open(ENERGY_MONITOR_LOG_PATH, 'r') as f:
                summary["energy_monitor"]["records"] = sum(
                    1 for line in f 
                    if re.search(r'Time: \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}, Power: [\d.]+ W', line)
                )
        
        # Count API records
        if API_LOG_PATH.exists():
            with open(API_LOG_PATH, 'r') as f:
                summary["api"]["records"] = sum(
                    1 for line in f 
                    if re.search(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}', line)
                )
        
        return summary
    except Exception as e:
        return {"error": f"Error generating log summary: {str(e)}"}

@app.get("/logs/historical-data")
async def get_historical_data(days: int = 7):
    """Get historical energy data from logs for specified number of days"""
    try:
        if not ENERGY_MONITOR_LOG_PATH.exists():
            return {"error": "Energy monitor log file not found"}
        
        cutoff_date = datetime.now() - timedelta(days=days)
        log_data = []
        
        with open(ENERGY_MONITOR_LOG_PATH, 'r') as f:
            for line in f:
                match = re.search(r'Time: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}), Power: ([\d.]+) W', line)
                if match:
                    timestamp_str = match.group(1)
                    watts = float(match.group(2))
                    
                    try:
                        timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
                        if timestamp >= cutoff_date:
                            log_data.append({
                                "timestamp": timestamp_str,
                                "watts": watts,
                                "date": timestamp.strftime('%Y-%m-%d'),
                                "hour": timestamp.hour
                            })
                    except ValueError:
                        continue
        
        # Group by date for daily statistics
        daily_stats = {}
        for record in log_data:
            date = record["date"]
            if date not in daily_stats:
                daily_stats[date] = {
                    "date": date,
                    "readings": [],
                    "avg_watts": 0,
                    "max_watts": 0,
                    "min_watts": float('inf'),
                    "total_readings": 0
                }
            
            daily_stats[date]["readings"].append(record["watts"])
            daily_stats[date]["max_watts"] = max(daily_stats[date]["max_watts"], record["watts"])
            daily_stats[date]["min_watts"] = min(daily_stats[date]["min_watts"], record["watts"])
            daily_stats[date]["total_readings"] += 1
        
        # Calculate averages
        for date in daily_stats:
            readings = daily_stats[date]["readings"]
            daily_stats[date]["avg_watts"] = sum(readings) / len(readings) if readings else 0
            daily_stats[date]["min_watts"] = daily_stats[date]["min_watts"] if daily_stats[date]["min_watts"] != float('inf') else 0
        
        return {
            "data": log_data,
            "daily_stats": list(daily_stats.values()),
            "total_records": len(log_data),
            "date_range": {
                "from": cutoff_date.strftime('%Y-%m-%d'),
                "to": datetime.now().strftime('%Y-%m-%d'),
                "days": days
            }
        }
    except Exception as e:
        return {"error": f"Error reading historical data: {str(e)}"}
