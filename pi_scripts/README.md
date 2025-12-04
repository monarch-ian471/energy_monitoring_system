# Raspberry Pi Energy Monitor Backend

Python-based backend service for real-time energy monitoring using Raspberry Pi 4 Model B with SCT-013 current sensor and PCF8591 ADC. Provides REST API endpoints for Flutter mobile app integration with SQLite data persistence and comprehensive logging.

## 📡 System Architecture

### Technology Stack
- **Hardware**: Raspberry Pi 4 Model B
- **Sensor**: SCT-013 Non-Invasive AC Current Sensor
- **ADC**: PCF8591 8-bit Analog-to-Digital Converter
- **Database**: SQLite3 (local file-based)
- **API Framework**: FastAPI 0.104.1
- **ASGI Server**: Uvicorn 0.24.0 (with standard extras)
- **I²C Library**: smbus2 0.4.3
- **HTTP Client**: Requests 2.31.0

### Core Components
```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                    │
│                  (Energy Consumption UI)                 │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTP/REST API
                       │ Port 8000
┌──────────────────────▼──────────────────────────────────┐
│              FastAPI Server (api.py)                     │
│  • CORS Enabled • JSON Responses • File Downloads       │
└──────────────┬────────────────────┬─────────────────────┘
               │                    │
               │                    │
┌──────────────▼─────────┐  ┌──────▼──────────────────────┐
│   SQLite Database      │  │  Log Files                  │
│   energy_data.db       │  │  • energy_monitor.log       │
│   • usage table        │  │  • api.log                  │
└────────────────────────┘  └─────────────────────────────┘
               ▲
               │
┌──────────────┴─────────────────────────────────────────┐
│        Energy Monitor Script (energy_monitor.py)       │
│        • I²C Communication • Data Collection           │
│        • Power Calculation • Database Writes           │
└──────────────┬─────────────────────────────────────────┘
               │ I²C Bus (smbus2)
┌──────────────▼─────────────────────────────────────────┐
│              PCF8591 ADC (0x48)                         │
│              8-bit A/D Converter                        │
└──────────────┬─────────────────────────────────────────┘
               │ Analog Signal
┌──────────────▼─────────────────────────────────────────┐
│         SCT-013 Current Sensor                          │
│         Non-Invasive AC Current Clamp                   │
└─────────────────────────────────────────────────────────┘
```

## 🛠️ Hardware Requirements

### Bill of Materials (BOM)

| Component | Specification | Quantity | Purpose |
|-----------|--------------|----------|---------|
| Raspberry Pi 4 Model B | 2GB+ RAM | 1 | Main computing unit |
| SCT-013 Current Sensor | 100A:50mA or 30A:1V | 1 | AC current measurement |
| PCF8591 ADC Module | 8-bit, I²C interface | 1 | Analog-to-digital conversion |
| Micro SD Card | 16GB+ Class 10 | 1 | OS and data storage |
| Power Supply | 5V 3A USB-C | 1 | Pi power |
| Breadboard | 830 points | 1 | Prototyping |
| Jumper Wires | M-F, M-M | 10+ | Connections |
| Resistors | 10kΩ, 470Ω | 2 | Voltage divider (if needed) |
| Capacitor | 10µF electrolytic | 1 | Signal filtering (optional) |

### SCT-013 Current Sensor Specifications

**Model Options:**
- **SCT-013-000**: 100A input, 50mA output (current output)
- **SCT-013-030**: 30A input, 1V output (voltage output) ← **Recommended**

**Key Features:**
- Non-invasive clamp design (no circuit breaking required)
- AC current measurement only
- Operating frequency: 50/60 Hz
- Phase shift: ≤5°
- Accuracy: ±1% (at rated current)
- Maximum continuous current: 120A (for 100A model)
- Cable length: ~1 meter
- Opening diameter: 13mm

### PCF8591 ADC Specifications

**Technical Details:**
- 8-bit resolution (0-255 values)
- 4 analog input channels (AIN0-AIN3)
- 1 analog output channel
- I²C interface address: **0x48** (default)
- Supply voltage: 2.5V - 6V
- Reference voltage: VCC (typically 5V)
- Conversion time: ~100µs
- Input impedance: 1MΩ

**Channel Configuration:**
- **AIN0**: SCT-013 sensor input (used in this project)
- **AIN1-AIN3**: Available for expansion

## 🔌 Hardware Setup & Wiring

### Complete Wiring Diagram

```
Raspberry Pi 4 GPIO Layout:
┌─────────────────────────────────────┐
│  3V3  (1) ● ● (2)  5V               │
│  SDA  (3) ● ● (4)  5V               │
│  SCL  (5) ● ● (6)  GND              │
│  GPIO (7) ● ● (8)  GPIO             │
│  GND  (9) ● ● (10) GPIO             │
│           ...                        │
└─────────────────────────────────────┘

PCF8591 Module Pinout:
┌────────────────────┐
│  VCC  GND  SDA  SCL│  ← I²C Bus
│  AIN0 AIN1 AIN2 AIN3│ ← Analog Inputs
│  AOUT              │  ← Analog Output
└────────────────────┘
```

### Step-by-Step Wiring Instructions

#### 1. PCF8591 to Raspberry Pi (I²C Bus)

```
PCF8591 Module    →    Raspberry Pi 4
─────────────────────────────────────
VCC               →    Pin 2  (5V)
GND               →    Pin 6  (GND)
SDA               →    Pin 3  (GPIO 2 / SDA)
SCL               →    Pin 5  (GPIO 3 / SCL)
```

**Important Notes:**
- Use **5V** power for PCF8591, not 3.3V (better ADC performance)
- Ensure solid connections; loose wires cause erratic readings
- Keep I²C wires short (<20cm) to minimize noise

#### 2. SCT-013 to PCF8591 ADC

```
SCT-013 Sensor         PCF8591 Module
──────────────────────────────────────
Red/Tip (Signal)   →   AIN0
Black/Sleeve (GND) →   GND
```

**Voltage Divider Circuit (if using SCT-013-000):**

If you have the **current output** version (SCT-013-000: 100A:50mA):

```
                  ┌─── to PCF8591 AIN0
                  │
   SCT-013 ───┬──┤
   (Signal)   │  10kΩ
              │  │
             ===  ─┬─── to PCF8591 GND
             33µF  │
              │   10kΩ
              └────┘
```

**Component Values:**
- Burden resistor: 10kΩ ± 1% (0.25W)
- Filter capacitor: 33µF electrolytic (optional, improves stability)
- This converts 50mA max to 0.5V signal (safe for ADC input)

**For SCT-013-030 (Voltage Output):**
- **Direct connection** to AIN0 (already outputs 0-1V)
- **No burden resistor needed**

#### 3. Complete Circuit Diagram

```
┌──────────────────────┐
│   AC Power Line      │
│   (Appliance Cable)  │
└──────────┬───────────┘
           │
           │  Clamp Around
           ▼  Hot Wire Only
     ┌─────────────┐
     │  SCT-013    │  Non-Invasive
     │   Sensor    │  Current Clamp
     └──────┬──────┘
            │ 3.5mm Jack
            │ (Analog Signal)
            ▼
      ┌─────────────┐
      │  PCF8591    │
      │  ADC Module │
      │  (0x48)     │
      └──────┬──────┘
             │ I²C Bus (SDA/SCL)
             │ + Power (5V/GND)
             ▼
    ┌────────────────┐
    │ Raspberry Pi 4 │
    │   GPIO Pins    │
    │   3,5,2,6      │
    └────────────────┘
```

### Safety Precautions ⚠️

1. **Never open electrical panels unless qualified**
2. **Never clamp around both hot and neutral wires** (cancels signal)
3. **Ensure proper insulation** on all exposed connections
4. **Do not exceed sensor ratings** (100A max for SCT-013-000)
5. **Test with low-power devices first** (e.g., lamp, phone charger)
6. **Use proper enclosure** for permanent installations

## 📦 Software Installation

### 1. Prepare Raspberry Pi OS

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential build tools
sudo apt install -y build-essential python3-dev python3-pip python3-venv \
                    git i2c-tools python3-smbus libjpeg-dev zlib1g-dev

# Enable I²C interface
sudo raspi-config
# Navigate: Interface Options → I2C → Yes → OK → Finish
```

**Verify I²C is enabled:**
```bash
# Check kernel modules
lsmod | grep i2c

# Expected output:
# i2c_bcm2835
# i2c_dev

# Scan I²C bus for devices
sudo i2cdetect -y 1
```

**Expected Output (with PCF8591 connected):**
```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- 48 -- -- -- -- -- -- --  ← PCF8591
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --
```

### 2. Clone Project Repository

```bash
cd ~
git clone <your-repository-url> energy-monitor
cd energy-monitor/pi_scripts
```

### 3. Create Python Virtual Environment

```bash
# Create isolated environment
python3 -m venv venv

# Activate environment
source venv/bin/activate

# Verify activation (prompt should show (venv))
which python3
# Expected: /home/pi/energy-monitor/pi_scripts/venv/bin/python3
```

### 4. Install Python Dependencies

```bash
# Upgrade pip first
pip install --upgrade pip setuptools wheel

# Install project requirements
pip install -r requirements.txt

# Verify installations
pip list
```

**Key Dependencies (from requirements.txt):**
```txt
fastapi==0.104.1          # Modern async web framework
uvicorn[standard]==0.24.0 # ASGI server with websockets
python-multipart==0.0.6   # Form data parsing
requests==2.31.0          # HTTP client
smbus2==0.4.3            # I²C bus library (pure Python)
```

### 5. Initialize Database Schema

```bash
# Run migration script to create tables
python3 migrate_database.py
```

**Output:**
```
Starting database migration...
Adding appliance_id column...
Adding appliance_name column...
Migration completed successfully.
✅ Total records for Appliance 1: 0
```

### 6. Test Hardware Connection

```bash
# Quick sensor test
python3 << 'EOF'
import smbus2 as smbus
import time

bus = smbus.SMBus(1)
address = 0x48

try:
    bus.write_byte(address, 0x00)  # Select AIN0
    time.sleep(0.1)
    data = bus.read_byte(address)
    voltage = (data / 255.0) * 3.3
    print(f"✅ PCF8591 connected successfully!")
    print(f"Raw ADC: {data}, Voltage: {voltage:.3f}V")
except Exception as e:
    print(f"❌ Connection failed: {e}")
EOF
```

## 🚀 Running the System

### Development Mode (Manual Start)

#### Terminal 1: Start Energy Monitor Data Collection

```bash
cd ~/energy-monitor/pi_scripts
source venv/bin/activate
python3 energy_monitor.py
```

**Expected Output:**
```
2024-12-04 10:30:45 - INFO - Energy Monitor started
2024-12-04 10:30:45 - INFO - Max ADC Value: 128, Max Voltage: 1.6544V, RMS Voltage: 1.1694V
2024-12-04 10:30:45 - INFO - Calculated Current: 22.2375A
2024-12-04 10:30:45 - INFO - Time: 2024-12-04 10:30:45, Power: 5114.63 W
```

**What This Does:**
- Reads PCF8591 ADC every 5 seconds
- Calculates RMS voltage and power
- Writes to SQLite database (`energy_data.db`)
- Logs to `energy_monitor.log`
- Continues until Ctrl+C

#### Terminal 2: Start API Server

```bash
cd ~/energy-monitor/pi_scripts
source venv/bin/activate

# Method 1: Using bash script
bash start_api.sh

# Method 2: Using Python runner
python3 run_api.py

# Method 3: Direct uvicorn command
uvicorn api:app --host 0.0.0.0 --port 8000 --reload
```

**Expected Output:**
```
Starting Energy Monitor API Server...
API will be available at: http://192.168.1.100:8000
Update your Flutter app's apiBaseUrl to: http://192.168.1.100:8000
Setting up logging...
   Starting server with logging enabled...
   Press Ctrl+C to stop the server

INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

**What This Does:**
- Starts FastAPI server on all interfaces (0.0.0.0)
- Enables CORS for Flutter app
- Serves REST API endpoints
- Logs requests to `api.log`
- Auto-reloads on code changes (--reload flag)

### Production Mode (Systemd Service)

#### 1. Create Systemd Service Files

**Energy Monitor Service:**
```bash
sudo nano /etc/systemd/system/energy-monitor.service
```

```ini
[Unit]
Description=Energy Monitor Data Collection Service
After=network.target
Wants=energy-api.service

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/energy-monitor/pi_scripts
Environment="PATH=/home/pi/energy-monitor/pi_scripts/venv/bin"
ExecStart=/home/pi/energy-monitor/pi_scripts/venv/bin/python3 energy_monitor.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**API Server Service:**
```bash
sudo nano /etc/systemd/system/energy-api.service
```

```ini
[Unit]
Description=Energy Monitor REST API Service
After=network.target energy-monitor.service
Requires=energy-monitor.service

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/energy-monitor/pi_scripts
Environment="PATH=/home/pi/energy-monitor/pi_scripts/venv/bin"
ExecStart=/home/pi/energy-monitor/pi_scripts/venv/bin/python3 run_api.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

#### 2. Enable and Start Services

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable services (start on boot)
sudo systemctl enable energy-monitor.service
sudo systemctl enable energy-api.service

# Start services now
sudo systemctl start energy-monitor.service
sudo systemctl start energy-api.service

# Check status
sudo systemctl status energy-monitor.service
sudo systemctl status energy-api.service
```

#### 3. Service Management Commands

```bash
# View real-time logs
sudo journalctl -u energy-monitor.service -f
sudo journalctl -u energy-api.service -f

# Stop services
sudo systemctl stop energy-monitor.service energy-api.service

# Restart services
sudo systemctl restart energy-monitor.service energy-api.service

# Disable autostart
sudo systemctl disable energy-monitor.service energy-api.service
```

## 📡 API Endpoints Reference

### Base URL
```
http://<RASPBERRY_PI_IP>:8000
```

### Interactive Documentation
- **Swagger UI**: http://192.168.1.100:8000/docs
- **ReDoc**: http://192.168.1.100:8000/redoc

### Endpoint Catalog

#### 1. Root & Health Check

**GET /** - API Information
```bash
curl http://192.168.1.100:8000/
```

**Response:**
```json
{
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
```

**GET /health** - System Health
```bash
curl http://192.168.1.100:8000/health
```

**Response:**
```json
{
  "status": "healthy",
  "database": "accessible",
  "energy_monitor_log": "exists",
  "api_log": "exists",
  "timestamp": "2024-12-04T10:30:45.123456"
}
```

#### 2. Current Energy Readings

**GET /energy** - Latest Power Reading
```bash
curl "http://192.168.1.100:8000/energy?appliance_id=1"
```

**Query Parameters:**
- `appliance_id` (optional, default=1): Appliance identifier

**Response:**
```json
{
  "timestamp": "2024-12-04 10:30:45",
  "watts": 125.5
}
```

**GET /appliances** - List All Appliances
```bash
curl http://192.168.1.100:8000/appliances
```

**Response:**
```json
{
  "appliances": [
    {"id": 1, "name": "Main Appliance"}
  ]
}
```

**GET /energy/{appliance_id}** - Specific Appliance Reading
```bash
curl http://192.168.1.100:8000/energy/1
```

**Response:**
```json
{
  "timestamp": "2024-12-04 10:30:45",
  "watts": 125.5,
  "appliance_id": 1,
  "appliance_name": "Main Appliance"
}
```

#### 3. Historical Data

**GET /energy/history** - Last 24 Readings
```bash
curl "http://192.168.1.100:8000/energy/history?appliance_id=1"
```

**Query Parameters:**
- `appliance_id` (optional, default=1)

**Response:**
```json
{
  "data": [
    {"timestamp": "2024-12-04 10:30:45", "watts": 125.5},
    {"timestamp": "2024-12-04 10:30:40", "watts": 123.2},
    ...
  ]
}
```

**GET /energy/history/{appliance_id}** - Custom Limit
```bash
curl "http://192.168.1.100:8000/energy/history/1?limit=100"
```

**Query Parameters:**
- `limit` (optional, default=24): Number of records

**Response:**
```json
{
  "appliance_id": 1,
  "data": [
    {"timestamp": "2024-12-04 10:30:45", "watts": 125.5},
    ...
  ]
}
```

#### 4. Log Data

**GET /logs/energy-monitor** - Parsed Energy Logs
```bash
curl http://192.168.1.100:8000/logs/energy-monitor
```

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-12-04 10:30:45",
      "watts": 125.5,
      "source": "energy_monitor"
    },
    ...
  ],
  "total_records": 1440,
  "file_size": 52480
}
```

**GET /logs/api** - API Access Logs
```bash
curl http://192.168.1.100:8000/logs/api
```

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-12-04 10:30:01",
      "message": "2024-12-04 10:30:01 - 192.168.1.50 - GET /energy HTTP/1.1 - 200",
      "source": "api"
    },
    ...
  ],
  "total_records": 450,
  "file_size": 18920
}
```

**GET /logs/summary** - Log Statistics
```bash
curl http://192.168.1.100:8000/logs/summary
```

**Response:**
```json
{
  "energy_monitor": {
    "exists": true,
    "size": 52480,
    "records": 1440
  },
  "api": {
    "exists": true,
    "size": 18920,
    "records": 450
  }
}
```

**GET /logs/historical-data** - Daily Aggregates
```bash
curl "http://192.168.1.100:8000/logs/historical-data?days=7"
```

**Query Parameters:**
- `days` (optional, default=7): Days to retrieve

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-12-04 10:30:45",
      "watts": 125.5,
      "date": "2024-12-04",
      "hour": 10
    },
    ...
  ],
  "daily_stats": [
    {
      "date": "2024-12-04",
      "avg_watts": 118.7,
      "max_watts": 180.5,
      "min_watts": 45.3,
      "total_readings": 288
    },
    ...
  ],
  "total_records": 2016,
  "date_range": {
    "from": "2024-11-27",
    "to": "2024-12-04",
    "days": 7
  }
}
```

#### 5. File Downloads

**GET /logs/download/energy-monitor** - Download Energy Log
```bash
curl -O http://192.168.1.100:8000/logs/download/energy-monitor
```

**Response:** `energy_monitor.log` file (text/plain)

**GET /logs/download/api** - Download API Log
```bash
curl -O http://192.168.1.100:8000/logs/download/api
```

**Response:** `api.log` file (text/plain)

## 🧪 Testing with Postman

### Postman Collection Setup

#### 1. Create New Collection

**Collection Details:**
- Name: "Energy Monitor API"
- Base URL Variable: `{{base_url}}` = `http://192.168.1.100:8000`

#### 2. Add Environment

**Environment Name:** "Energy Monitor - Raspberry Pi"

**Variables:**
```
base_url     | http://192.168.1.100:8000  | (Replace with your Pi IP)
appliance_id | 1                           |
days         | 7                           |
```

#### 3. Request Examples

**Health Check Request:**
```
GET {{base_url}}/health
```

**Expected Response:** 200 OK
```json
{
  "status": "healthy",
  "database": "accessible",
  "energy_monitor_log": "exists",
  "api_log": "exists",
  "timestamp": "2024-12-04T10:30:45.123456"
}
```

**Current Energy Request:**
```
GET {{base_url}}/energy?appliance_id={{appliance_id}}
```

**Energy History Request:**
```
GET {{base_url}}/energy/history?appliance_id={{appliance_id}}
```

**Historical Data with Stats:**
```
GET {{base_url}}/logs/historical-data?days={{days}}
```

**Download Log File:**
```
GET {{base_url}}/logs/download/energy-monitor
```

**Response Settings:**
- Save Response: Body → Save to File

### Automated Testing Scripts

**Test Runner Script (test_api.py):**
```bash
# Run comprehensive API tests
python3 test_api.py
```

**Features:**
- Creates sample data if database is empty
- Tests all GET endpoints
- Validates JSON response formats
- Tests file download endpoints
- Saves downloaded logs for inspection

**Test Output Example:**
```
Energy Monitor API Test
========================================
Database connection successful. Found 144 records.

🔍 Testing API Endpoints
========================================

🔍 Testing Current energy usage (/energy):
   Status Code: 200
   Response: {
     "timestamp": "2024-12-04 10:30:45",
     "watts": 125.5
   }
   ✅ /energy response format is correct

...
```

## 🔧 Configuration & Calibration

### Sensor Calibration

The system uses a calibration factor to convert ADC voltage to actual current:

**In energy_monitor.py:**
```python
VOLTAGE = 230.0              # Grid voltage (adjust for your region)
CALIBRATION_FACTOR = 19.02   # Current multiplier (A/V)
```

#### Calibration Process

1. **Connect a known load** (e.g., 100W incandescent bulb)
2. **Measure actual current** with a clamp meter
3. **Read sensor voltage** from logs
4. **Calculate factor:**

```
Actual Current (A) = 100W / 230V = 0.435A
Sensor Voltage (V) = 0.023V (from log)
Calibration Factor = 0.435 / 0.023 = 18.91
```

5. **Update in code:**
```python
CALIBRATION_FACTOR = 18.91  # Your calculated value
```

6. **Restart service:**
```bash
sudo systemctl restart energy-monitor.service
```

### Multi-Appliance Configuration

**To monitor multiple appliances:**

1. **Hardware:** Connect additional SCT-013 sensors to AIN1, AIN2, AIN3
2. **Update energy_monitor.py:**

```python
# Define appliances
APPLIANCES = [
    {"id": 1, "name": "Refrigerator", "channel": 0},
    {"id": 2, "name": "Air Conditioner", "channel": 1},
    {"id": 3, "name": "Water Heater", "channel": 2}
]

# In main loop:
for appliance in APPLIANCES:
    channel = appliance["channel"]
    bus.write_byte(address, 0x40 | channel)  # Select channel
    time.sleep(0.01)
    data = bus.read_byte(address)
    # ... calculate power for this appliance
    c.execute('INSERT INTO usage VALUES (?, ?, ?, ?)',
              (timestamp, power, appliance["id"], appliance["name"]))
```

### Database Schema

**Table: usage**
```sql
CREATE TABLE usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    watts REAL NOT NULL,
    appliance_id INTEGER DEFAULT 1,
    appliance_name TEXT DEFAULT 'Main Appliance'
);
```

**Indexes (for performance):**
```sql
CREATE INDEX idx_timestamp ON usage(timestamp);
CREATE INDEX idx_appliance ON usage(appliance_id);
```

### Logging Configuration

**JSON Config (logging_config.json):**
```json
{
  "version": 1,
  "formatters": {
    "default": {
      "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    }
  },
  "handlers": {
    "file": {
      "class": "logging.FileHandler",
      "filename": "api.log",
      "formatter": "default"
    }
  },
  "loggers": {
    "uvicorn": {
      "handlers": ["file"],
      "level": "INFO"
    }
  }
}
```

**Log Rotation (add to cron):**
```bash
# Rotate logs weekly
0 0 * * 0 gzip /home/pi/energy-monitor/pi_scripts/energy_monitor.log && \
          mv /home/pi/energy-monitor/pi_scripts/energy_monitor.log.gz \
             /home/pi/energy-monitor/logs/archive/energy_$(date +\%Y\%m\%d).log.gz
```

## 🐛 Troubleshooting

### I²C Device Not Detected

**Symptom:** `sudo i2cdetect -y 1` shows no device at 0x48

**Solutions:**
```bash
# 1. Check wiring connections
# 2. Verify I²C is enabled
sudo raspi-config  # Interface Options → I2C → Enable

# 3. Load I²C kernel modules
sudo modprobe i2c-dev
sudo modprobe i2c-bcm2835

# 4. Make permanent
echo "i2c-dev" | sudo tee -a /etc/modules
echo "i2c-bcm2835" | sudo tee -a /etc/modules

# 
