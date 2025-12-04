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

# 5. Check PCF8591 is powered (5V, not 3.3V)
# 6. Reboot
sudo reboot
```

### Erratic or Zero Readings

**Symptom:** Power readings are 0W, negative, or wildly fluctuating

**Common Causes & Solutions:**

1. **Sensor Not Clamped Properly**
   - Ensure clamp is fully closed with audible "click"
   - Clamp around **single hot wire only**, not both wires
   - Orient sensor arrow with current flow direction

2. **No Load Connected**
   - Turn on appliance being monitored
   - Check appliance is actually drawing power

3. **Wrong Calibration Factor**
   ```bash
   # Test with known load (100W bulb)
   python3 energy_monitor.py
   # Adjust CALIBRATION_FACTOR until reading matches expected
   ```

4. **ADC Not Reading**
   ```bash
   # Test PCF8591 directly
   python3 << 'EOF'
   import smbus2 as smbus
   import time
   
   bus = smbus.SMBus(1)
   bus.write_byte(0x48, 0x00)
   time.sleep(0.1)
   for i in range(10):
       data = bus.read_byte(0x48)
       print(f"Raw ADC: {data}, Voltage: {(data/255.0)*3.3:.3f}V")
       time.sleep(0.5)
   EOF
   ```

5. **Loose Wiring**
   - Re-seat all jumper wires
   - Use multimeter to verify continuity
   - Check breadboard connections

### API Not Accessible from Phone/Mac

**Symptom:** Flutter app can't reach API

**Solutions:**

1. **Verify Pi IP Address**
   ```bash
   hostname -I
   # Use first IP (e.g., 192.168.1.100)
   ```

2. **Check API is Running**
   ```bash
   sudo systemctl status energy-api.service
   # or
   curl http://localhost:8000/health
   ```

3. **Test from Mac**
   ```bash
   # From Mac terminal
   curl http://192.168.1.100:8000/health
   ```

4. **Firewall Issues**
   ```bash
   # Check if ufw is active
   sudo ufw status
   
   # Allow port 8000
   sudo ufw allow 8000/tcp
   
   # Or disable firewall (not recommended for production)
   sudo ufw disable
   ```

5. **Router/Network Issues**
   - Ensure Mac and Pi are on same network
   - Check router isn't blocking traffic
   - Try pinging Pi from Mac: `ping 192.168.1.100`

### Database Errors

**Symptom:** "Database locked" or "No such table: usage"

**Solutions:**

1. **Run Migration**
   ```bash
   cd ~/energy-monitor/pi_scripts
   python3 migrate_database.py
   ```

2. **Check Database Permissions**
   ```bash
   ls -la energy_data.db
   # Should show: -rw-r--r-- 1 pi pi
   
   # Fix permissions if needed
   chmod 664 energy_data.db
   chown pi:pi energy_data.db
   ```

3. **Database Locked**
   ```bash
   # Stop all services accessing database
   sudo systemctl stop energy-monitor.service energy-api.service
   
   # Check for locked database
   sudo lsof | grep energy_data.db
   
   # Restart services
   sudo systemctl start energy-monitor.service energy-api.service
   ```

### High CPU Usage

**Symptom:** Pi running hot, high CPU in `htop`

**Solutions:**

1. **Increase Sampling Interval**
   ```python
   # In energy_monitor.py, change:
   time.sleep(5)  # Increase from 5 to 10 seconds
   ```

2. **Disable Uvicorn Auto-Reload**
   ```python
   # In run_api.py, change:
   uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=False)
   ```

3. **Reduce Logging Verbosity**
   ```python
   # In logging_config.json, change:
   "level": "WARNING"  # Instead of "INFO"
   ```

### Service Won't Start

**Symptom:** `sudo systemctl start energy-monitor.service` fails

**Solutions:**

1. **Check Logs**
   ```bash
   sudo journalctl -u energy-monitor.service -n 50 --no-pager
   ```

2. **Test Manually**
   ```bash
   cd ~/energy-monitor/pi_scripts
   source venv/bin/activate
   python3 energy_monitor.py
   # Look for error messages
   ```

3. **Common Issues:**
   - Wrong path in service file
   - Python dependencies missing: `pip install -r requirements.txt`
   - I²C not enabled
   - Permissions issue: `sudo chmod +x energy_monitor.py`

## 📊 Postman Testing Guide (macOS)

### Initial Setup

1. **Launch Postman 11.70.6** on Mac
2. **Create New Workspace**
   - Name: "Energy Monitor Testing"
   - Type: Personal
3. **Create Collection**
   - Name: "Raspberry Pi Energy Monitor API"
   - Description: "Complete API endpoint tests for energy monitoring system"

### Environment Configuration

**Create Environment:** "Raspberry Pi Dev"

**Variables to Add:**

| Variable | Type | Initial Value | Current Value |
|----------|------|---------------|---------------|
| base_url | default | http://192.168.1.100:8000 | http://192.168.1.100:8000 |
| appliance_id | default | 1 | 1 |
| days_lookback | default | 7 | 7 |
| history_limit | default | 24 | 24 |

**Steps:**
1. Click "Environments" (left sidebar)
2. Click "+" to create new environment
3. Name it "Raspberry Pi Dev"
4. Add variables listed above
5. Click "Save"
6. Select this environment from dropdown (top-right)

### Request Collection Structure

Create folders in your collection:

```
📁 Raspberry Pi Energy Monitor API
  ├── 📁 1. Health & Info
  │   ├── GET Root Info
  │   └── GET Health Check
  ├── 📁 2. Current Data
  │   ├── GET Current Energy (Default)
  │   ├── GET Current Energy (Specific Appliance)
  │   └── GET All Appliances List
  ├── 📁 3. Historical Data
  │   ├── GET Energy History (Default)
  │   ├── GET Energy History (Custom Limit)
  │   └── GET Historical Data with Stats
  ├── 📁 4. Log Management
  │   ├── GET Energy Monitor Logs
  │   ├── GET API Access Logs
  │   └── GET Logs Summary
  └── 📁 5. File Downloads
      ├── GET Download Energy Log
      └── GET Download API Log
```

### Detailed Request Configurations

#### 1. Health & Info

**Request 1: GET Root Info**
```
Method: GET
URL: {{base_url}}/
Headers: None required
```

**Tests Tab (add these scripts):**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has version info", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('version');
    pm.expect(jsonData.version).to.eql('1.0.0');
});

pm.test("Response has endpoints list", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('endpoints');
    pm.expect(jsonData.endpoints).to.have.property('current_energy');
});
```

**Request 2: GET Health Check**
```
Method: GET
URL: {{base_url}}/health
Headers: None required
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("System is healthy", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.status).to.eql('healthy');
});

pm.test("Database is accessible", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.database).to.eql('accessible');
});

pm.test("Logs exist", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.energy_monitor_log).to.eql('exists');
    pm.expect(jsonData.api_log).to.eql('exists');
});

pm.test("Response has timestamp", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('timestamp');
});
```

#### 2. Current Data

**Request 3: GET Current Energy (Default)**
```
Method: GET
URL: {{base_url}}/energy
Params: 
  - Key: appliance_id | Value: {{appliance_id}}
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has required fields", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('timestamp');
    pm.expect(jsonData).to.have.property('watts');
});

pm.test("Watts is a number", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.watts).to.be.a('number');
});

pm.test("Timestamp format is valid", function () {
    var jsonData = pm.response.json();
    var timestampPattern = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/;
    pm.expect(jsonData.timestamp).to.match(timestampPattern);
});

// Save current reading for comparison
pm.environment.set("last_watts", pm.response.json().watts);
```

**Request 4: GET Current Energy (Specific Appliance)**
```
Method: GET
URL: {{base_url}}/energy/{{appliance_id}}
Headers: None required
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response includes appliance details", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('appliance_id');
    pm.expect(jsonData).to.have.property('appliance_name');
    pm.expect(jsonData.appliance_id).to.eql(1);
});
```

**Request 5: GET All Appliances List**
```
Method: GET
URL: {{base_url}}/appliances
Headers: None required
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response contains appliances array", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('appliances');
    pm.expect(jsonData.appliances).to.be.an('array');
});

pm.test("At least one appliance exists", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.appliances.length).to.be.above(0);
});

pm.test("Appliance has required fields", function () {
    var jsonData = pm.response.json();
    var appliance = jsonData.appliances[0];
    pm.expect(appliance).to.have.property('id');
    pm.expect(appliance).to.have.property('name');
});
```

#### 3. Historical Data

**Request 6: GET Energy History (Default)**
```
Method: GET
URL: {{base_url}}/energy/history
Params:
  - Key: appliance_id | Value: {{appliance_id}}
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has data array", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('data');
    pm.expect(jsonData.data).to.be.an('array');
});

pm.test("Data array has records", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.length).to.be.above(0);
});

pm.test("Each record has timestamp and watts", function () {
    var jsonData = pm.response.json();
    jsonData.data.forEach(function(record) {
        pm.expect(record).to.have.property('timestamp');
        pm.expect(record).to.have.property('watts');
    });
});

pm.test("Default returns up to 24 records", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.length).to.be.at.most(24);
});
```

**Request 7: GET Energy History (Custom Limit)**
```
Method: GET
URL: {{base_url}}/energy/history/{{appliance_id}}
Params:
  - Key: limit | Value: {{history_limit}}
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response includes appliance_id", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('appliance_id');
    pm.expect(jsonData.appliance_id).to.eql(parseInt(pm.environment.get("appliance_id")));
});

pm.test("Data respects limit parameter", function () {
    var jsonData = pm.response.json();
    var limit = parseInt(pm.environment.get("history_limit"));
    pm.expect(jsonData.data.length).to.be.at.most(limit);
});
```

**Request 8: GET Historical Data with Stats**
```
Method: GET
URL: {{base_url}}/logs/historical-data
Params:
  - Key: days | Value: {{days_lookback}}
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has data and daily_stats", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('data');
    pm.expect(jsonData).to.have.property('daily_stats');
    pm.expect(jsonData).to.have.property('total_records');
});

pm.test("Daily stats has correct structure", function () {
    var jsonData = pm.response.json();
    if (jsonData.daily_stats.length > 0) {
        var stat = jsonData.daily_stats[0];
        pm.expect(stat).to.have.property('date');
        pm.expect(stat).to.have.property('avg_watts');
        pm.expect(stat).to.have.property('max_watts');
        pm.expect(stat).to.have.property('min_watts');
        pm.expect(stat).to.have.property('total_readings');
    }
});

pm.test("Date range matches request", function () {
    var jsonData = pm.response.json();
    var requestedDays = parseInt(pm.environment.get("days_lookback"));
    pm.expect(jsonData.date_range.days).to.eql(requestedDays);
});
```

#### 4. Log Management

**Request 9: GET Energy Monitor Logs**
```
Method: GET
URL: {{base_url}}/logs/energy-monitor
Headers: None required
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has log data", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('data');
    pm.expect(jsonData).to.have.property('total_records');
    pm.expect(jsonData).to.have.property('file_size');
});

pm.test("Log records have correct source", function () {
    var jsonData = pm.response.json();
    if (jsonData.data.length > 0) {
        jsonData.data.forEach(function(record) {
            pm.expect(record.source).to.eql('energy_monitor');
        });
    }
});
```

**Request 10: GET API Access Logs**
```
Method: GET
URL: {{base_url}}/logs/api
Headers: None required
```

**Request 11: GET Logs Summary**
```
Method: GET
URL: {{base_url}}/logs/summary
Headers: None required
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Summary has both log types", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('energy_monitor');
    pm.expect(jsonData).to.have.property('api');
});

pm.test("Log files exist", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.energy_monitor.exists).to.be.true;
    pm.expect(jsonData.api.exists).to.be.true;
});

pm.test("Record counts are numbers", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.energy_monitor.records).to.be.a('number');
    pm.expect(jsonData.api.records).to.be.a('number');
});
```

#### 5. File Downloads

**Request 12: GET Download Energy Log**
```
Method: GET
URL: {{base_url}}/logs/download/energy-monitor
Headers: None required
```

**Tests Tab:**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Content-Type is text/plain", function () {
    pm.expect(pm.response.headers.get('Content-Type')).to.include('text/plain');
});

pm.test("Response body is not empty", function () {
    pm.expect(pm.response.text()).to.have.lengthOf.above(0);
});
```

**Request 13: GET Download API Log**
```
Method: GET
URL: {{base_url}}/logs/download/api
Headers: None required
```

### Running Collection Tests

**Option 1: Manual Run**
1. Click "Runner" button (top-left)
2. Select "Raspberry Pi Energy Monitor API" collection
3. Select "Raspberry Pi Dev" environment
4. Click "Run Raspberry Pi Energy Monitor API"
5. Review results

**Option 2: Collection Runner Settings**
```
Iterations: 1
Delay: 500ms (between requests)
Data: None
Save responses: Checked
Persist variables: Checked
```

**Expected Results:**
- All tests should pass (green checkmarks)
- Response times < 500ms for most endpoints
- No 404 or 500 errors

### Debugging Failed Tests

**If tests fail:**

1. **Check Pi Connectivity**
   ```bash
   # From Mac terminal
   ping 192.168.1.100
   curl -v http://192.168.1.100:8000/health
   ```

2. **Verify Environment Variables**
   - Check `base_url` matches Pi IP
   - Ensure no trailing slashes in URL

3. **Check Pi Services**
   ```bash
   # SSH into Pi
   ssh pi@192.168.1.100
   sudo systemctl status energy-api.service
   ```

4. **View Request/Response**
   - Click failed request in Postman
   - Check "Body" tab for error details
   - Review "Console" (View → Show Postman Console)

## 📈 Performance Monitoring

### Key Metrics to Track

1. **API Response Times**
   - Target: < 200ms for current data
   - Target: < 500ms for historical data

2. **Database Size Growth**
   ```bash
   # Check database size
   ls -lh energy_data.db
   
   # Count records
   sqlite3 energy_data.db "SELECT COUNT(*) FROM usage;"
   ```

3. **Log File Sizes**
   ```bash
   du -h energy_monitor.log api.log
   ```

4. **System Resources**
   ```bash
   # CPU and memory usage
   htop
   
   # Service-specific
   systemctl status energy-monitor.service energy-api.service
   ```

### Optimization Tips

1. **Add Database Indexes**
   ```sql
   CREATE INDEX IF NOT EXISTS idx_timestamp ON usage(timestamp DESC);
   CREATE INDEX IF NOT EXISTS idx_appliance_time ON usage(appliance_id, timestamp DESC);
   ```

2. **Implement Log Rotation**
   ```bash
   # Add to /etc/logrotate.d/energy-monitor
   /home/pi/energy-monitor/pi_scripts/*.log {
       daily
       rotate 7
       compress
       missingok
       notifempty
   }
   ```

3. **Database Vacuum (Weekly)**
   ```bash
   # Add to crontab
   0 3 * * 0 sqlite3 /home/pi/energy-monitor/pi_scripts/energy_data.db "VACUUM;"
   ```

## 📚 Additional Resources

### Documentation
- FastAPI Docs: https://fastapi.tiangolo.com/
- Uvicorn Docs: https://www.uvicorn.org/
- SQLite Tutorial: https://www.sqlitetutorial.net/
- PCF8591 Datasheet: https://www.nxp.com/docs/en/data-sheet/PCF8591.pdf
- SCT-013 Info: https://openenergymonitor.org/

### Community Support
- Raspberry Pi Forums: https://forums.raspberrypi.com/
- FastAPI Discord: https://discord.gg/fastapi
- Energy Monitoring: https://community.openenergymonitor.org/
