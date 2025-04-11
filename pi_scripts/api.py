from fastapi import FastAPI
import sqlite3

app = FastAPI()

@app.get("/energy")
async def get_energy():
	conn = sqlite3.connect('/home/ian0407/energy_data.db')
	c = conn.cursor()
	c.execute("SELECT timestamp, watts FROM usage ORDER BY timestamp DESC LIMIT 1")
	data = c.fetchone()
	conn.close()
	if data:
		return {"timestamp": data[0], "watts": data[1]}
	return {"error": "No data available"}

@app.get("/energy/history")
async def get_history():
	conn = sqlite3.connect('/home/ian0407/energy_data.db')
	c = conn.cursor()
	c.execute("SELECT timestamp, watts FROM usage ORDER BY timestamp DESC LIMIT 24")
	dat = c.fetchall()
	conn.close()
	return [{"timestamp": row[0], "watts": row[1]} for row in data]
