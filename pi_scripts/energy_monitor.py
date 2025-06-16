import time
import smbus2 as smbus
import sqlite3
import math

bus = smbus.SMBus(1)
address = 0x48

conn = sqlite3.connect('/home/ian0407/pi_scripts/energy_data.db')
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
    print(f"Max ADC Value: {max_adc}, Max Voltage: {max_value:.4f}V, RMS Voltage: {rms_voltage:.4f}V")
    return rms_voltage

def calculate_power():
    raw_voltage = read_voltage() 
    print(f"Calculated Current: {raw_voltage * CALIBRATION_FACTOR:.4f}A")
    current = raw_voltage * CALIBRATION_FACTOR  
    power = abs(current) * VOLTAGE / 1000
    return power

try:
    while True:
        power = calculate_power()
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        c.execute('INSERT INTO usage (timestamp, watts) VALUES (?, ?)', (timestamp, power))
        conn.commit()
        print(f"Time: {timestamp}, Power: {power:.2f} W")
        time.sleep(5)
except KeyboardInterrupt:
    print("Stopped by user")
    conn.close()
    exit(0)
except Exception as e:
    print(f"Error: {e}")
    conn.close()
    exit(1)
