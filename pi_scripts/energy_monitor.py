import time
import smbus2 as smbus
import sqlite3
import math
from pathlib import Path
import logging
from datetime import datetime

bus = smbus.SMBus(1)
address = 0x48

# Get the directory where this script is located
SCRIPT_DIR = Path(__file__).parent.absolute()
DB_PATH = SCRIPT_DIR / "energy_data.db"

# Setup logging
LOG_FILE = SCRIPT_DIR / "energy_monitor.log"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()  # Also print to console
    ]
)
logger = logging.getLogger(__name__)

conn = sqlite3.connect(str(DB_PATH))
c = conn.cursor()
c.execute('CREATE TABLE IF NOT EXISTS usage (timestamp TEXT, watts REAL)')
conn.commit()

VOLTAGE = 230.0
CALIBRATION_FACTOR = 19.02

def read_voltage():
    samples = 10
    max_value = 0
    max_adc = 0
    bus.write_byte(address, 0x00)
    time.sleep(0.01)
    bus.read_byte(address)  # Discard stale reading
    for _ in range(samples):
        time.sleep(0.001)
        data = bus.read_byte(address)
        voltage = (data / 255) * 3.3
        if voltage > max_value:
            max_adc = data
            max_value = voltage
    rms_voltage = max_value / math.sqrt(2) if max_value > 0 else 0
    logger.info(f"Max ADC Value: {max_adc}, Max Voltage: {max_value:.4f}V, RMS Voltage: {rms_voltage:.4f}V")
    return rms_voltage

def calculate_power():
    raw_voltage = read_voltage() 
    logger.info(f"Calculated Current: {raw_voltage * CALIBRATION_FACTOR:.4f}A")
    current = raw_voltage * CALIBRATION_FACTOR  
    power = abs(current) * VOLTAGE / 1000
    return power

try:
    logger.info("Energy Monitor started")
    while True:
        power = calculate_power()
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        c.execute('INSERT INTO usage (timestamp, watts) VALUES (?, ?)', (timestamp, power))
        conn.commit()
        log_message = f"Time: {timestamp}, Power: {power:.2f} W"
        logger.info(log_message)
        print(log_message)  # Keep console output for compatibility
        time.sleep(5)
except KeyboardInterrupt:
    logger.info("Energy Monitor stopped by user")
    print("Stopped by user")
    conn.close()
    exit(0)
except Exception as e:
    logger.error(f"Energy Monitor error: {e}")
    print(f"Error: {e}")
    conn.close()
    exit(1)
