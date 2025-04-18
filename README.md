**Real-Time Energy Monitoring System**

A system to monitor energy usage in real-time using a Raspberry Pi and a Flutter mobile

**Overview**

- Flutter App: Displays real-time energy data, historical charts, and generates PDF
- Raspberry Pi Scripts: Collects energy data and serves it via an API

**Directory Structure**

- *flutter_app/*: Flutter application source code
- *pi_scripts/*: Python scripts for the Raspberry Pi

**Prerequisites**

- Flutter: Stable channel (e.g., 3.22.x), Dart 3.x.
- Python: 3.9+ on Raspberry Pi.
- Raspberry Pi: Running Raspberry Pi OS 64-bit

**Setup**
**---**
**Flutter App**
1. Navigate to '*flutter_app/*':
	bash
	*cd flutter_app*

2. Install dependencies:
	bash
	*flutter pub get*

3. Update <Pi-IP> in lib.main.dart with your Rasberry Pi's IP (e.g., *192.168.1.100*).

4. Run on an emulator or device
	bash
	*flutter run --no-enable-impeller*

**Raspberry Pi Scripts**
1. Copy pi_scripts/ to your Raspberry Pi (e.g., */home/pi/*):
	bash
	*scp -r pi_scripts/ pi@<pi-ip>:~/*

2. Install Python dependencies (e.g., *fastapi, uvicorn*):
	bash
	*pip3 install fastapi uvicorn*

3. Run the energy monitoring scripts:
	bash
	*python3 ~/pi_scripts/energy_monitor.py*

4. Run the API server
	bash
	*uvicorn pi_scripts.api:app --host 0.0.0.0 --port 8000*

**Usage**
- Launch the Fluuter app to view real-time energy data from the Pi.
- Use the "Refresh" button to update data manually.
- Generate PDF reports via the PDF icon.
- Toggle "Advanced Mode" for future features.

**Dependencies**
- Flutter: http, sqflite, fl_chart, pdf, printing, path_provider, path.
- Python: fastapi, uvicorn.

**License**

MIT License

Copyright (c) 2025 Ian Katengeza

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

