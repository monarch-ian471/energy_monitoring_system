import time
import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from  adafruit_ads1x15.analog_in import AnalogIn
import sqlite3

#Initializing I2c and ADs1115
i2c = busio.I2C(board.SCK, board.SDA)
ads = ADS.ADS1115(i2c)
chan = AnalogIn(ads, ADS.P0)

#Setting up SQLite database
conn = sqlite3.connect('/home/pi/energy_data.db')
c = conn.cursor()
c.execute('''CREATE TABLE IF NOT EXISTS usage
            (timestamp TEXT, watts REAL)''')
conn.commit()

#Constants and factual
VOLTAGE = 000 #I will have to adjust for my region
CALIBRATION_FACTOR = 20 #Adjust based on sensor / resistor (33 Omega burden resistor (1/4W)

def calculate_power():
	raw_voltage = chan.voltage
	current = raw_voltage * CALIBRATION_FACTOR
	power = current * VOLTAGE
	return power

#The Main Loop
try:
	while True:
		power = calculate_power()
		timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
		c.execute("INSERT INTO usage (timestamp, watts) VALUES (?, ?)",
				(timestamp, power))
		conn.commit()
		print(f"Time: {timestamp}, Power: {power:.2f} W")
		time.sleep(5)
finally:
	conn.close()
