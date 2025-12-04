# Raspberry Pi Energy Monitor Backend

Python-based backend service for real-time energy monitoring using Raspberry Pi with INA219 current sensor. Provides REST API endpoints for the Flutter mobile app and handles data logging, historical analysis, and multiple appliance tracking.

## 📡 Features

### Core Functionality
- **Real-time Energy Monitoring**: Read power consumption via INA219 sensor over I²C
- **REST API Server**: FastAPI-based endpoints for mobile app integration
- **Multi-Appliance Support**: Track up to 3 appliances independently
- **Persistent Logging**: Automatic CSV logging with rotation
- **Historical Data Analysis**: Daily statistics and aggregated metrics
- **CORS Enabled**: Secure cross-origin requests from Flutter app
- **Automatic Startup**: Systemd service for production deployment

### API Endpoints
- `GET /energy?applianceId=1` - Current energy reading
- `GET /energy/history?applianceId=1` - Last 24 readings
- `GET /logs/historical-data?days=7` - Historical data with daily stats
- `GET /logs/download/energy-monitor` - Download energy monitor log
- `GET /logs/download/api` - Download API access log
- `GET /appliances` - List all configured appliances

## 🛠️ Hardware Requirements

### Components
- **Raspberry Pi**: Model 3B+ or newer (tested on Pi 4)
- **INA219 Current Sensor**: High-side DC current sensor breakout
- **Power Supply**: 5V 3A USB-C (for Pi 4) or Micro-USB (for Pi 3)
- **SD Card**: 16GB+ Class 10 or better
- **Breadboard & Jumper Wires**: For prototyping
- **Optional**: Enclosure for permanent installation

### INA219 Specifications
- **Voltage Range**: 0-26V DC
- **Current Range**: ±3.2A (with 0.1Ω shunt resistor)
- **Interface**: I²C (address 0x40 default)
- **Resolution**: 12-bit ADC
- **Accuracy**: ±0.5% (typical)

## 🔌 Hardware Setup

### INA219 Wiring

Connect the INA219 sensor to Raspberry Pi GPIO:

```
INA219          Raspberry Pi
------          ------------
VCC      →      Pin 1  (3.3V)
GND      →      Pin 6  (GND)
SCL      →      Pin 5  (GPIO 3 - I2C SCL)
SDA      →      Pin 3  (GPIO 2 - I2C SDA)
VIN+     →      Positive side of load
VIN-     →      Negative side of load
```

**Circuit Diagram:**
```
[Power Source +] → [INA219 VIN+] → [Load/Appliance +]
[Load/Appliance -] → [INA219 VIN-] → [Power Source -]
```

### Enable I²C on Raspberry Pi

1. **Using raspi-config:**
```bash
sudo raspi-config
# Select: Interface Options → I2C → Enable
```

2. **Manual configuration:**
```bash
sudo nano /boot/config.txt
# Add or uncomment:
dtparam=i2c_arm=on
```

3. **Reboot:**
```bash
sudo reboot
```

4. **Verify I²C is enabled:**
```bash
sudo i2cdetect -y 1
```
You should see device at address `0x40`.

### Multiple INA219 Sensors (Optional)

For monitoring multiple appliances, use sensors with different I²C addresses:
- Sensor 1: `0x40` (default, A0 & A1 not connected)
- Sensor 2: `0x41` (A0 connected to VS+)
- Sensor 3: `0x44` (A1 connected to VS+)

Configure in code:
```python
APPLIANCES = [
    {"id": 1, "name": "Refrigerator", "address": 0x40},
    {"id": 2, "name": "Air Conditioner", "address": 0x41},
    {"id": 3, "name": "Water Heater", "address": 0x44}
]
```

## 📦 Software Installation

### Prerequisites

1. **Update system:**
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Install Python 3 and pip:**
```bash
sudo apt install python3 python3-pip python3-venv -y
```

3. **Install I²C tools:**
```bash
sudo apt install i2c-tools python3-smbus -y
```

4. **Install system dependencies:**
```bash
sudo apt install git libjpeg-dev zlib1g-dev -y
```

### Clone Repository

```bash
cd ~
git clone <repository-url>
cd pi_scripts
```

### Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Key dependencies:**
- `fastapi==0.115.6` - Modern web framework
- `uvicorn==0.34.0` - ASGI server
- `adafruit-circuitpython-ina219==3.4.24` - INA219 sensor library
- `adafruit-blinka==8.49.0` - CircuitPython compatibility layer

### Verify Installation

Test sensor connectivity:
```bash
python3
>>> import board
>>> import busio
>>> import adafruit_ina219
>>> i2c = busio.I2C(board.SCL, board.SDA)
>>> ina = adafruit_ina219.INA219(i2c)
>>> print(f"Voltage: {ina.bus_voltage:.2f}V")
>>> print(f"Current: {ina.current:.2f}mA")
```

## 🚀 Running the Service

### Development Mode

Start the API server manually:
```bash
cd ~/pi_scripts
source venv/bin/activate
python3 energy_monitor_api.py
```

Server runs on `http://0.0.0.0:8000`

Test endpoints:
```bash
# From another terminal or device on same network
curl http://PI_IP:8000/energy
curl http://PI_IP:8000/energy/history
curl http://PI_IP:8000/appliances
```

### Production Mode (Systemd Service)

1. **Create service file:**
```bash
sudo nano /etc/systemd/system/energy-monitor.service
```

2. **Add configuration:**
```ini
[Unit]
Description=Energy Monitor API Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/pi_scripts
Environment="PATH=/home/pi/pi_scripts/venv/bin"
ExecStart=/home/pi/pi_scripts/venv/bin/python3 /home/pi/pi_scripts/energy_monitor_api.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

3. **Enable and start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable energy-monitor.service
sudo systemctl start energy-monitor.service
```

4. **Check status:**
```bash
sudo systemctl status energy-monitor.service
```

5. **View logs:**
```bash
sudo journalctl -u energy-monitor.service -f
```

### Service Management Commands

```bash
# Start service
sudo systemctl start energy-monitor.service

# Stop service
sudo systemctl stop energy-monitor.service

# Restart service
sudo systemctl restart energy-monitor.service

# Disable autostart
sudo systemctl disable energy-monitor.service

# View real-time logs
sudo journalctl -u energy-monitor.service -f
```

## 📁 File Structure

```
pi_scripts/
├── energy_monitor_api.py      # Main FastAPI server
├── requirements.txt            # Python dependencies
├── logs/                       # Log directory (auto-created)
│   ├── energy_monitor.log     # Energy readings CSV
│   └── api_access.log         # API request logs
├── README.md                   # This file
└── venv/                       # Virtual environment (gitignored)
```

## 🔧 Configuration

### Sensor Calibration

The INA219 may require calibration for accurate readings. Adjust in code:

```python
# energy_monitor_api.py

# Option 1: Adjust shunt resistor value (default 0.1Ω)
ina = adafruit_ina219.INA219(i2c, addr=0x40)
# If using 0.05Ω shunt:
# Calibrate accordingly (see Adafruit documentation)

# Option 2: Apply correction factor
CALIBRATION_FACTOR = 1.02  # Adjust based on known load testing
watts_calibrated = watts * CALIBRATION_FACTOR
```

### Appliance Configuration

Edit `APPLIANCES` list in `energy_monitor_api.py`:

```python
APPLIANCES = [
    {"id": 1, "name": "Refrigerator", "address": 0x40},
    {"id": 2, "name": "Air Conditioner", "address": 0x41},
    {"id": 3, "name": "Water Heater", "address": 0x44}
]
```

### Log Rotation

Default: 7 days of data retention. Modify in code:

```python
# Keep only last 7 days
cutoff = datetime.now() - timedelta(days=7)
```

For longer retention:
```python
cutoff = datetime.now() - timedelta(days=30)  # 30 days
```

### API Port Configuration

Change default port (8000):
```python
# energy_monitor_api.py
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)  # Use port 8080
```

Update Flutter app `constants.dart` accordingly.

## 📊 API Documentation

### Interactive API Docs

Once server is running, visit:
- **Swagger UI**: `http://PI_IP:8000/docs`
- **ReDoc**: `http://PI_IP:8000/redoc`

### Endpoint Details

#### 1. Get Current Energy
```http
GET /energy?applianceId=1
```

**Response:**
```json
{
  "timestamp": "2024-12-04T10:30:45.123456",
  "watts": 125.5,
  "applianceId": 1
}
```

#### 2. Get Energy History
```http
GET /energy/history?applianceId=1
```

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-12-04T10:30:00",
      "watts": 120.3,
      "applianceId": 1
    },
    ...
  ]
}
```

#### 3. Get Historical Data with Stats
```http
GET /logs/historical-data?days=7
```

**Response:**
```json
{
  "data": [...],
  "daily_stats": [
    {
      "date": "2024-12-04",
      "avg_watts": 115.2,
      "max_watts": 180.5,
      "min_watts": 45.3,
      "total_readings": 144
    },
    ...
  ]
}
```

#### 4. Download Logs
```http
GET /logs/download/energy-monitor
GET /logs/download/api
```

**Response:** CSV file download

#### 5. List Appliances
```http
GET /appliances
```

**Response:**
```json
{
  "appliances": [
    {"id": 1, "name": "Refrigerator"},
    {"id": 2, "name": "Air Conditioner"},
    {"id": 3, "name": "Water Heater"}
  ]
}
```

## 🔍 Monitoring & Debugging

### Check Sensor Connection

```bash
# Detect I²C devices
sudo i2cdetect -y 1

# Expected output:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- --
# 10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 40: 40 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --  ← INA219 detected
# 50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# 70: -- -- -- -- -- -- -- --
```

### Test Sensor Readings

```bash
cd ~/pi_scripts
source venv/bin/activate
python3 << EOF
import board
import busio
import adafruit_ina219

i2c = busio.I2C(board.SCL, board.SDA)
ina = adafruit_ina219.INA219(i2c)

print(f"Bus Voltage:   {ina.bus_voltage:.3f} V")
print(f"Shunt Voltage: {ina.shunt_voltage / 1000:.6f} V")
print(f"Current:       {ina.current:.3f} mA")
print(f"Power:         {ina.power:.3f} mW")
EOF
```

### View Live Logs

```bash
# Service logs (systemd)
sudo journalctl -u energy-monitor.service -f

# Application logs
tail -f ~/pi_scripts/logs/api_access.log
tail -f ~/pi_scripts/logs/energy_monitor.log
```

### Check Resource Usage

```bash
# CPU and memory
htop

# Service-specific
systemctl status energy-monitor.service
```

## 🐛 Troubleshooting

### Problem: I²C Device Not Detected

**Solution:**
```bash
# Enable I²C
sudo raspi-config  # Interface Options → I2C → Enable

# Load I²C kernel modules
sudo modprobe i2c-dev
sudo modprobe i2c-bcm2835

# Add to /etc/modules for persistence
echo "i2c-dev" | sudo tee -a /etc/modules
echo "i2c-bcm2835" | sudo tee -a /etc/modules
```

### Problem: Permission Denied (I²C)

**Solution:**
```bash
# Add user to i2c group
sudo usermod -a -G i2c pi

# Logout and login again, or:
sudo reboot
```

### Problem: Inaccurate Readings

**Solutions:**
1. **Check wiring** - Ensure solid connections
2. **Calibrate sensor** - Test with known load (e.g., 60W bulb)
3. **Verify voltage range** - Ensure load doesn't exceed 26V
4. **Check shunt resistor** - Confirm 0.1Ω rating

### Problem: Service Won't Start

**Solution:**
```bash
# Check service logs
sudo journalctl -u energy-monitor.service -n 50

# Common issues:
# - Wrong path in service file
# - Python dependencies missing
# - I²C not enabled

# Test manually
cd ~/pi_scripts
source venv/bin/activate
python3 energy_monitor_api.py
```

### Problem: API Not Accessible from Phone

**Solutions:**
1. **Check firewall:**
```bash
sudo ufw allow 8000/tcp
# Or disable firewall temporarily:
sudo ufw disable
```

2. **Verify Pi IP address:**
```bash
hostname -I
```

3. **Test from Pi itself:**
```bash
curl http://localhost:8000/energy
```

4. **Check Flutter app configuration** - Ensure `apiBaseUrl` has correct IP

### Problem: High CPU Usage

**Solution:**
```python
# In energy_monitor_api.py, adjust reading interval:
await asyncio.sleep(2)  # Increase from 1 to 2 seconds
```

## 📈 Performance Optimization

### Reduce Logging Frequency

For battery-powered setups or reduced writes:
```python
# Log every 5 minutes instead of every reading
if reading_count % 5 == 0:
    log_reading(watts)
```

### Database Alternative

For high-frequency logging, consider SQLite:
```python
import sqlite3

conn = sqlite3.connect("energy_data.db")
cursor = conn.cursor()
cursor.execute('''
    CREATE TABLE IF NOT EXISTS readings (
        timestamp TEXT,
        watts REAL,
        appliance_id INTEGER
    )
''')
```

### Network Optimization

Enable response compression:
```python
# In energy_monitor_api.py
from fastapi.middleware.gzip import GZipMiddleware
app.add_middleware(GZipMiddleware, minimum_size=1000)
```

## 🔒 Security Considerations

### API Authentication (Optional)

For production deployment, add API key authentication:

```python
from fastapi import Security, HTTPException
from fastapi.security import APIKeyHeader

API_KEY = "your-secret-key"
api_key_header = APIKeyHeader(name="X-API-Key")

def verify_api_key(api_key: str = Security(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return api_key

@app.get("/energy")
async def get_energy(api_key: str = Security(verify_api_key)):
    # ... existing code
```

Update Flutter app to include header:
```dart
headers: {"X-API-Key": "your-secret-key"}
```

### HTTPS/SSL (Recommended)

Use reverse proxy (nginx) with Let's Encrypt:
```bash
sudo apt install nginx certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## 📝 Data Format

### Energy Monitor Log (CSV)

```csv
timestamp,watts,appliance_id
2024-12-04 10:00:00,125.5,1
2024-12-04 10:01:00,130.2,1
2024-12-04 10:02:00,118.7,2
```

### API Access Log

```
2024-12-04 10:00:01 - INFO - GET /energy?applianceId=1
2024-12-04 10:00:15 - INFO - GET /energy/history
```

## 🔄 Backup & Recovery

### Backup Configuration

```bash
# Backup logs and config
cd ~
tar -czf energy-monitor-backup-$(date +%Y%m%d).tar.gz pi_scripts/
```

### Restore from Backup

```bash
tar -xzf energy-monitor-backup-20241204.tar.gz
cd pi_scripts
source venv/bin/activate
python3 energy_monitor_api.py
```

### Automated Daily Backups

Add to crontab:
```bash
crontab -e
# Add:
0 2 * * * tar -czf ~/backups/energy-monitor-$(date +\%Y\%m\%d).tar.gz ~/pi_scripts/logs/
```

## 🤝 Contributing

1. Test changes on physical hardware
2. Update this README with new features
3. Follow PEP 8 style guidelines
4. Add error handling for edge cases

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- **Adafruit**: INA219 CircuitPython library
- **FastAPI**: Modern Python web framework
- **Raspberry Pi Foundation**: Affordable computing platform

## 📞 Support

For issues:
- Check hardware connections first
- Review logs: `sudo journalctl -u energy-monitor.service -f`
- Test sensor independently before debugging API
- Ensure Flutter app is configured correctly (see `flutter_app/README.md`)

---
