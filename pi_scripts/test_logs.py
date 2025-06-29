#!/usr/bin/env python3
"""
Test script for log-related API endpoints
"""
import requests
import json
from pathlib import Path
from datetime import datetime, timedelta
import random

# Configuration
API_BASE_URL = "http://localhost:8000"
SCRIPT_DIR = Path(__file__).parent.absolute()

def create_sample_log_data():
    """Create sample log data for testing"""
    print("Creating sample log data...")
    
    # Create sample energy monitor log
    energy_log_path = SCRIPT_DIR / "energy_monitor.log"
    with open(energy_log_path, 'w') as f:
        base_time = datetime.now() - timedelta(days=7)
        for i in range(24 * 7):  # 7 days of hourly data
            timestamp = base_time + timedelta(hours=i)
            watts = 30 + random.randint(0, 50) + random.random() * 10
            f.write(f"Time: {timestamp.strftime('%Y-%m-%d %H:%M:%S')}, Power: {watts:.2f} W\n")
    
    # Create sample API log
    api_log_path = SCRIPT_DIR / "api.log"
    with open(api_log_path, 'w') as f:
        base_time = datetime.now() - timedelta(days=3)
        for i in range(50):  # 50 API requests
            timestamp = base_time + timedelta(hours=i/2)
            f.write(f"{timestamp.strftime('%Y-%m-%d %H:%M:%S')} - 192.168.1.100 - GET /energy HTTP/1.1 - 200\n")
    
    print("Sample log data created successfully")

def test_log_endpoints():
    """Test log-related API endpoints"""
    endpoints = [
        ("/logs/summary", "Logs summary"),
        ("/logs/energy-monitor", "Energy monitor logs"),
        ("/logs/api", "API logs"),
        ("/logs/historical-data", "Historical data (7 days)"),
        ("/logs/historical-data?days=3", "Historical data (3 days)")
    ]
    
    for endpoint, description in endpoints:
        try:
            response = requests.get(f"{API_BASE_URL}{endpoint}")
            print(f"\n🔍 Testing {description} ({endpoint}):")
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"   Response: {json.dumps(data, indent=2)}")
                
                # Validate response format
                if endpoint == "/logs/summary":
                    if "energy_monitor" in data and "api" in data:
                        print("/logs/summary response format is correct")
                        print(f"Energy monitor: {data['energy_monitor']['records']} records")
                        print(f"API: {data['api']['records']} records")
                    else:
                        print("/logs/summary response format incorrect")
                
                elif endpoint.startswith("/logs/energy-monitor"):
                    if "data" in data and isinstance(data["data"], list):
                        print("/logs/energy-monitor response format is correct")
                        print(f"Found {len(data['data'])} log records")
                    else:
                        print("/logs/energy-monitor response format incorrect")
                
                elif endpoint.startswith("/logs/historical-data"):
                    if "data" in data and "daily_stats" in data:
                        print("/logs/historical-data response format is correct")
                        print(f"Found {len(data['data'])} historical records")
                        print(f"Daily stats: {len(data['daily_stats'])} days")
                    else:
                        print("/logs/historical-data response format incorrect")
            else:
                print(f"Request failed with status {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"Could not connect to API at {API_BASE_URL}")
        except Exception as e:
            print(f"Error testing {endpoint}: {e}")

def test_download_endpoints():
    """Test log download endpoints"""
    download_endpoints = [
        ("/logs/download/energy-monitor", "energy_monitor.log"),
        ("/logs/download/api", "api.log")
    ]
    
    for endpoint, filename in download_endpoints:
        try:
            print(f"\n📥 Testing download {filename} ({endpoint}):")
            response = requests.get(f"{API_BASE_URL}{endpoint}")
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 200:
                # Save downloaded file
                download_path = SCRIPT_DIR / f"downloaded_{filename}"
                with open(download_path, 'wb') as f:
                    f.write(response.content)
                print(f"Downloaded {filename} successfully")
                print(f"Saved to: {download_path}")
            else:
                print(f"Download failed with status {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"Could not connect to API at {API_BASE_URL}")
        except Exception as e:
            print(f"Error downloading {filename}: {e}")

if __name__ == "__main__":
    print("🚀 Energy Monitor Log API Test")
    print("=" * 40)
    
    # Create sample log data
    create_sample_log_data()
    
    # Test log endpoints
    print("\n Testing Log API Endpoints")
    print("=" * 40)
    test_log_endpoints()
    
    # Test download endpoints
    print("\n Testing Download Endpoints")
    print("=" * 40)
    test_download_endpoints()
    
    print("\n Test Summary:")
    print("1. Make sure the API server is running: uvicorn api:app --host 0.0.0.0 --port 8000")
    print("2. Log files are now available for historical data analysis")
    print("3. Download endpoints allow Flutter app to get log files")
    print("4. Historical data endpoint provides daily statistics") 