# Log Integration for Energy Monitoring System

## 📊 Overview

The Energy Monitoring System now includes comprehensive log file integration that allows the Flutter app to:
- **Visualize Historical Data**: Display energy usage patterns over time
- **Download Log Files**: Save log files locally for analysis
- **Daily Statistics**: View aggregated daily energy statistics
- **Real-time Monitoring**: Access both current and historical data

## 🏗️ Architecture

```
Raspberry Pi Logs → FastAPI Endpoints → Flutter App → Charts & Downloads
     ↓                    ↓                    ↓
energy_monitor.log    /logs/* endpoints    Historical Views
api.log              /logs/download/*     File Downloads
```

## 📁 Log Files

### Energy Monitor Log (`energy_monitor.log`)
- **Location**: `pi_scripts/energy_monitor.log`
- **Format**: `Time: 2024-01-15 14:30:25, Power: 43.50 W`
- **Content**: Real-time energy readings from hardware sensors
- **Frequency**: Every 5 seconds when monitoring is active

### API Log (`api.log`)
- **Location**: `pi_scripts/api.log`
- **Format**: `2024-01-15 14:30:25 - 192.168.1.100 - GET /energy HTTP/1.1 - 200`
- **Content**: API request history and system events
- **Frequency**: Every API request

## 🔌 New API Endpoints

### 1. GET `/logs/summary`
Returns summary statistics for both log files.

**Response:**
```json
{
  "energy_monitor": {
    "exists": true,
    "size": 1024,
    "records": 150
  },
  "api": {
    "exists": true,
    "size": 512,
    "records": 75
  }
}
```

### 2. GET `/logs/energy-monitor`
Returns parsed energy monitor log data.

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-01-15 14:30:25",
      "watts": 43.5,
      "source": "energy_monitor"
    }
  ],
  "total_records": 150,
  "file_size": 1024
}
```

### 3. GET `/logs/api`
Returns parsed API log data.

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-01-15 14:30:25",
      "message": "GET /energy HTTP/1.1 - 200",
      "source": "api"
    }
  ],
  "total_records": 75,
  "file_size": 512
}
```

### 4. GET `/logs/historical-data?days=7`
Returns historical energy data with daily statistics.

**Response:**
```json
{
  "data": [
    {
      "timestamp": "2024-01-15 14:30:25",
      "watts": 43.5,
      "date": "2024-01-15",
      "hour": 14
    }
  ],
  "daily_stats": [
    {
      "date": "2024-01-15",
      "avg_watts": 42.3,
      "max_watts": 65.2,
      "min_watts": 28.1,
      "total_readings": 1728
    }
  ],
  "total_records": 12096,
  "date_range": {
    "from": "2024-01-08",
    "to": "2024-01-15",
    "days": 7
  }
}
```

### 5. GET `/logs/download/energy-monitor`
Downloads the energy monitor log file.

### 6. GET `/logs/download/api`
Downloads the API log file.

## 📱 Flutter App Integration

### New Features Added

#### 1. **Download Button**
- **Location**: App bar (download icon)
- **Function**: Opens dialog to download log files
- **Permissions**: Requests storage permission automatically

#### 2. **Historical Data Loading**
- **Button**: "Load Historical Data" in History page
- **Function**: Fetches 7 days of historical data
- **Display**: Shows daily statistics cards

#### 3. **Enhanced History Page**
- **Daily Statistics**: Horizontal scrollable cards showing daily averages
- **Time Range Buttons**: Day, Week, Month view options
- **Historical Charts**: Enhanced with log data

#### 4. **File Download Dialog**
```dart
Future<void> _showLogDownloadDialog() async {
  // Shows dialog with download options for both log files
}
```

### New Dependencies Added

```yaml
dependencies:
  permission_handler: ^11.3.1  # For file download permissions
```

## 🚀 Setup Instructions

### 1. **Raspberry Pi Setup**

```bash
# Navigate to pi_scripts directory
cd pi_scripts

# Install dependencies
pip3 install -r requirements.txt

# Start the API server with logging
./start_api.sh
```

### 2. **Flutter App Setup**

```bash
# Navigate to flutter_app directory
cd flutter_app

# Install dependencies
flutter pub get

# Update API URL in main.dart
const String apiBaseUrl = 'http://YOUR_PI_IP:8000';
```

### 3. **Testing Log Integration**

```bash
# Test log endpoints
cd pi_scripts
python3 test_logs.py

# Test API server
curl http://localhost:8000/logs/summary
```

## 📊 Data Visualization

### Daily Statistics Cards
- **Average Watts**: Daily average energy consumption
- **Maximum Watts**: Peak energy usage for the day
- **Minimum Watts**: Lowest energy usage for the day
- **Total Readings**: Number of data points collected

### Historical Charts
- **Time Range**: 1 day, 7 days, 30 days
- **Data Source**: Combined real-time and log data
- **Interactive**: Zoom, pan, and tooltip support

### Download Features
- **File Location**: External storage directory
- **File Names**: `energy_monitor.log`, `api.log`
- **Permissions**: Automatic storage permission request

## 🔧 Configuration

### Log File Paths
```python
# In api.py
SCRIPT_DIR = Path(__file__).parent.absolute()
API_LOG_PATH = SCRIPT_DIR / "api.log"
ENERGY_MONITOR_LOG_PATH = SCRIPT_DIR / "energy_monitor.log"
```

### Logging Configuration
```json
// logging_config.json
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
      "filename": "api.log"
    }
  }
}
```

## Usage Examples

### 1. **View Daily Statistics**
1. Open Flutter app
2. Navigate to History tab
3. Tap "Load Historical Data"
4. View daily statistics cards

### 2. **Download Log Files**
1. Tap download icon in app bar
2. Select log file type
3. Grant storage permission
4. File saved to device storage

### 3. **Analyze Historical Trends**
1. Load historical data
2. Use Day/Week/Month view buttons
3. Interact with charts (zoom, pan)
4. View tooltips for detailed information

## Troubleshooting

### Common Issues

1. **"Log file not found"**
   - Ensure energy_monitor.py is running
   - Check file permissions in pi_scripts directory
   - Verify log files exist: `ls -la *.log`

2. **"Storage permission denied"**
   - Grant storage permission in app settings
   - Check Android/iOS permission settings
   - Ensure app has file access permissions

3. **"No historical data"**
   - Run energy_monitor.py to generate log data
   - Check API server is running
   - Verify network connectivity

4. **"Download failed"**
   - Check API server status
   - Verify log file exists on Pi
   - Check network connectivity

### Debug Commands

```bash
# Check log files exist
ls -la pi_scripts/*.log

# Test API endpoints
curl http://PI_IP:8000/logs/summary

# Check log file content
tail -n 10 pi_scripts/energy_monitor.log

# Monitor API server logs
tail -f pi_scripts/api.log
```

## API Response Examples

### Successful Historical Data Response
```json
{
  "data": [
    {
      "timestamp": "2024-01-15 14:30:25",
      "watts": 43.5,
      "date": "2024-01-15",
      "hour": 14
    }
  ],
  "daily_stats": [
    {
      "date": "2024-01-15",
      "avg_watts": 42.3,
      "max_watts": 65.2,
      "min_watts": 28.1,
      "total_readings": 1728
    }
  ],
  "total_records": 12096,
  "date_range": {
    "from": "2024-01-08",
    "to": "2024-01-15",
    "days": 7
  }
}
```

### Error Response
```json
{
  "error": "Energy monitor log file not found"
}
```

## Benefits

1. **Historical Analysis**: View energy usage patterns over time
2. **Data Export**: Download log files for external analysis
3. **Performance Monitoring**: Track system performance and API usage
4. **Offline Access**: Cached data available when offline
5. **User Insights**: Daily statistics help users understand energy patterns

## Future Enhancements

1. **Advanced Analytics**: Machine learning insights
2. **Export Formats**: CSV, Excel, PDF reports
3. **Real-time Alerts**: Energy usage notifications
4. **Data Compression**: Efficient log storage
5. **Cloud Integration**: Remote log storage and analysis

## upport

For issues or questions:
1. Check the troubleshooting section
2. Run `test_logs.py` to diagnose problems
3. Verify API server is running
4. Check log file permissions and content
5. Test network connectivity between devices 