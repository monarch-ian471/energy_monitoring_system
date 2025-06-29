# Energy Monitor API Setup

This directory contains the Python API server and energy monitoring scripts for the Energy Monitoring System.

## 🏗️ Architecture

```
Flutter App (Mobile/Web) ←→ Python FastAPI Server ←→ SQLite Database ←→ Energy Monitor Script
```

## 📁 Files

- `api.py` - FastAPI server with endpoints for energy data
- `energy_monitor.py` - Script to read energy data from hardware sensors
- `test_api.py` - Test script to verify API functionality
- `start_api.sh` - Startup script for the API server
- `requirements.txt` - Python dependencies
- `energy_data.db` - SQLite database (created automatically)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd pi_scripts
pip3 install -r requirements.txt
```

### 2. Start the API Server

```bash
# Option 1: Use the startup script (recommended)
./start_api.sh

# Option 2: Manual start
uvicorn api:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Test the API

```bash
python3 test_api.py
```

### 4. Update Flutter App Configuration

In `flutter_app/lib/main.dart`, update the `apiBaseUrl`:

```dart
// Replace with your Raspberry Pi's IP address
const String apiBaseUrl = 'http://YOUR_PI_IP:8000';
```

## 🔌 API Endpoints

### GET /energy
Returns the latest energy reading.

**Response:**
```json
{
  "timestamp": "2024-01-15 14:30:25",
  "watts": 43.5
}
```

### GET /energy/history
Returns the last 24 energy readings.

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-01-15 14:30:25",
      "watts": 43.5
    },
    {
      "timestamp": "2024-01-15 14:25:20",
      "watts": 42.1
    }
  ]
}
```

## 🔧 Configuration

### Database Path
The API automatically uses a database file in the same directory as the scripts:
- Database: `energy_data.db`
- Location: Same directory as `api.py`

### Network Access
- The API runs on `0.0.0.0:8000` to allow network access
- Find your Pi's IP: `hostname -I`
- Update Flutter app to use: `http://PI_IP:8000`

## 🧪 Testing

### Manual Testing
```bash
# Test current energy
curl http://localhost:8000/energy

# Test history
curl http://localhost:8000/energy/history
```

### Automated Testing
```bash
python3 test_api.py
```

## 🔍 Troubleshooting

### Common Issues

1. **"Import fastapi could not be resolved"**
   - Install dependencies: `pip3 install -r requirements.txt`

2. **"Database error"**
   - Run `energy_monitor.py` first to create the database
   - Check file permissions in the pi_scripts directory

3. **Flutter app can't connect**
   - Verify API server is running: `curl http://PI_IP:8000/energy`
   - Check firewall settings on the Pi
   - Ensure correct IP address in Flutter app

4. **No data showing**
   - Run `energy_monitor.py` to collect data
   - Use `test_api.py` to create sample data

### Debug Mode

Enable debug logging in the API:
```bash
uvicorn api:app --host 0.0.0.0 --port 8000 --reload --log-level debug
```

## 📊 Data Flow

1. **Hardware Reading**: `energy_monitor.py` reads from I2C sensors
2. **Data Storage**: Energy readings stored in SQLite database
3. **API Access**: FastAPI server provides REST endpoints
4. **Mobile App**: Flutter app fetches and displays data
5. **Offline Support**: App caches data locally for offline viewing

## 🔒 Security Notes

- The API currently has no authentication (for development)
- Consider adding authentication for production use
- Database file should be protected from unauthorized access
- Use HTTPS in production environments

## 📈 Performance

- API responses typically < 100ms
- Database queries optimized with indexes
- Flutter app implements caching for offline support
- Real-time updates every 5 seconds from hardware

## 🛠️ Development

### Adding New Endpoints

1. Add endpoint to `api.py`
2. Update `test_api.py` to test new endpoint
3. Update Flutter app to use new endpoint
4. Test with `python3 test_api.py`

### Database Schema

```sql
CREATE TABLE usage (
    timestamp TEXT,
    watts REAL
);
```

### Error Handling

The API returns consistent error responses:
```json
{
  "error": "Error description"
}
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Run `test_api.py` to diagnose problems
3. Check API logs for detailed error messages
4. Verify network connectivity between devices 