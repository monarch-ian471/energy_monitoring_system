#!/bin/bash

# Energy Monitor API Startup Script
echo "Starting Energy Monitor API Server..."

# Check if we're in the right directory
if [ ! -f "api.py" ]; then
    echo "Error: api.py not found. Please run this script from the pi_scripts directory."
    exit 1
fi

# Check if requirements are installed
echo "Checking dependencies..."
python3 -c "import fastapi, uvicorn" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
fi

# Get the local IP address for network access
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "API will be available at: http://192.168.1.138:8000"
echo "Update your Flutter app's apiBaseUrl to: http://192.168.1.138:8000"

# Create log directory if it doesn't exist
echo "Setting up logging..."
touch api.log
touch energy_monitor.log

# Start the API server with logging
echo "   Starting server with logging enabled..."
echo "   Press Ctrl+C to stop the server"
echo "   Logs will be saved to api.log"
echo ""

# Start uvicorn with access logging to file
uvicorn api:app --host 0.0.0.0 --port 8000 --reload --access-log --log-config=logging_config.json 2>&1 | tee -a api.log 
