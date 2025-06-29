#!/usr/bin/env python3
import requests
import json
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta
import random

# Configuration
API_BASE_URL = "http://localhost:8000"
SCRIPT_DIR = Path(__file__).parent.absolute()
DB_PATH = SCRIPT_DIR / "energy_data.db"

def test_database_connection():
    """Test if database exists and has data"""
    try:
        conn = sqlite3.connect(str(DB_PATH))
        c = conn.cursor()
        c.execute("SELECT COUNT(*) FROM usage")
        count = c.fetchone()[0]
        conn.close()
        print(f"Database connection successful. Found {count} records.")
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False

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

def test_api_endpoints():
    """Test all API endpoints"""
    endpoints = [
        ("/energy", "Current energy usage"),
        ("/energy/history", "Energy history"),
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
                
                # Validate response format based on endpoint
                if endpoint == "/energy":
                    if "watts" in data and "timestamp" in data:
                        print("/energy response format is correct")
                    else:
                        print("/energy response missing required fields")
                        
                elif endpoint == "/energy/history":
                    if "data" in data and isinstance(data["data"], list):
                        print("/energy/history response format is correct")
                        print(f"Found {len(data['data'])} history records")
                    else:
                        print("/energy/history response format incorrect")
                
                elif endpoint.startswith("/logs/summary"):
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
            print(f"\n Testing download {filename} ({endpoint}):")
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

def create_sample_data():
    """Create sample data if database is empty"""
    try:
        conn = sqlite3.connect(str(DB_PATH))
        c = conn.cursor()
        c.execute("SELECT COUNT(*) FROM usage")
        count = c.fetchone()[0]
        
        if count == 0:
            print("Creating sample database data...")
            import time
            from datetime import datetime, timedelta
            
            # Create 24 hours of sample data
            base_time = datetime.now() - timedelta(hours=24)
            for i in range(24):
                timestamp = base_time + timedelta(hours=i)
                watts = 30 + (i % 20)  # Varying power usage
                c.execute("INSERT INTO usage (timestamp, watts) VALUES (?, ?)", 
                         (timestamp.strftime('%Y-%m-%d %H:%M:%S'), watts))
            
            conn.commit()
            print("Sample database data created successfully")
        else:
            print(f"Database already contains {count} records")
            
        conn.close()
    except Exception as e:
        print(f"Error creating sample data: {e}")

if __name__ == "__main__":
    print("Energy Monitor API Test")
    print("=" * 40)
    
    # Test database
    if test_database_connection():
        create_sample_data()
    else:
        print("Please run energy_monitor.py first to create the database")
    
    # Create sample log data
    create_sample_log_data()
    
    # Test API endpoints
    print("\n Testing API Endpoints")
    print("=" * 40)
    test_api_endpoints()
    
    # Test download endpoints
    print("\n Testing Download Endpoints")
    print("=" * 40)
    test_download_endpoints()
    
    print("\n Test Summary:")
    print("1. Make sure the API server is running: uvicorn api:app --host 0.0.0.0 --port 8000")
    print("2. Ensure the Flutter app is configured to connect to the correct IP address")
    print("3. Check that all endpoints return the expected JSON format")
    print("4. Log files are now available for historical data analysis")
    print("5. Download endpoints allow Flutter app to get log files") 