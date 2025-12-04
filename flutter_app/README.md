# Energy Monitor Flutter App

A comprehensive energy monitoring application built with Flutter, featuring real-time energy tracking, historical data visualization, AI-powered insights, and gamification elements.

## 📱 Features

### Core Functionality
- **Real-time Energy Monitoring**: Track current energy usage with live updates
- **Multi-Appliance Support**: Monitor multiple appliances independently
- **Historical Data Visualization**: View energy usage patterns with interactive charts
- **Offline-First Architecture**: Works seamlessly without internet connectivity
- **Multi-Language Support**: Available in English and Chichewa (Nyanja)

### Advanced Features
- **AI Energy Insights**: Get personalized recommendations based on usage patterns
- **Energy Challenge**: Gamified quiz system to learn about energy efficiency
- **Achievement System**: Earn badges for energy-saving milestones
- **Push Notifications**: Real-time alerts for high usage and daily summaries
- **Profile Management**: Multiple user profiles with individual tracking
- **Data Export**: Download energy logs in CSV format
- **Dark/Light Theme**: Adaptive UI with theme switching

### Visualizations
- **Radial Gauge**: Real-time energy usage indicator
- **Spline Charts**: Historical usage trends
- **Daily Statistics**: Aggregated metrics with min/max/average values
- **Energy Impact Scorecard**: Quick overview of key metrics

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── l10n/                          # Internationalization
│   ├── app_en.arb                # English translations
│   ├── app_ny.arb                # Chichewa translations
│   └── app_localizations*.dart   # Generated localization files
├── src/
│   ├── core/                     # Core utilities
│   │   ├── constants.dart        # App-wide constants
│   │   ├── error_handler.dart    # Error handling
│   │   └── theme/
│   │       └── theme_provider.dart
│   ├── data/                     # Data layer
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── sqlite_datasource.dart
│   │   │   └── remote/
│   │   │       └── api_datasource.dart
│   │   └── repositories/
│   │       └── energy_repository_impl.dart
│   ├── domain/                   # Business logic
│   │   ├── entities/
│   │   │   └── energy_data.dart
│   │   ├── repositories/
│   │   │   └── energy_repository.dart
│   │   └── use_cases/
│   │       ├── get_current_energy.dart
│   │       └── get_energy_history.dart
│   ├── presentation/             # UI layer
│   │   ├── providers/
│   │   │   └── energy_provider.dart
│   │   ├── screens/
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── energy_dashboard.dart
│   │   │   └── energy_challenge_screen.dart
│   │   └── widgets/
│   │       └── ai_energy_insights.dart
│   └── services/
│       └── notification_service.dart
├── firebase_options.dart         # Firebase configuration
└── main.dart                     # App entry point
```

## 🛠️ Tech Stack

### Core Dependencies
- **Flutter SDK**: ^3.0.0
- **Dart**: ^3.0.0

### State Management & Architecture
- **flutter_riverpod**: ^2.6.1 - Reactive state management
- **provider**: ^6.1.2 - Additional state management
- **freezed**: ^2.5.7 - Immutable data classes
- **json_serializable**: ^6.8.0 - JSON serialization

### Data & Storage
- **sqflite**: ^2.4.1 - Local SQLite database
- **sqflite_common_ffi**: ^2.3.3 - FFI support for desktop
- **sqflite_common_ffi_web**: ^0.4.5+3 - Web database support
- **path**: ^1.9.0 - File path manipulation

### UI Components
- **syncfusion_flutter_gauges**: ^27.2.5 - Radial gauges
- **syncfusion_flutter_charts**: ^27.2.5 - Interactive charts
- **lottie**: ^3.1.3 - Animated illustrations

### Networking
- **http**: ^1.2.2 - HTTP requests
- **connectivity_plus**: ^6.1.1 - Network connectivity

### Firebase Services
- **firebase_core**: ^3.8.1
- **firebase_messaging**: ^15.2.1
- **flutter_local_notifications**: ^18.0.1

### Accessibility & Media
- **speech_to_text**: ^7.0.0 - Voice input
- **flutter_tts**: ^4.2.0 - Text-to-speech
- **image_picker**: ^1.1.2 - Image selection

### Internationalization
- **intl**: ^0.19.0 - Date/number formatting
- **flutter_localizations**: SDK - Localization support

### Permissions
- **permission_handler**: ^11.3.1 - Runtime permissions
- **path_provider**: ^2.1.5 - File system paths

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Raspberry Pi with energy monitoring API running (see `pi_scripts/README.md`)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd flutter_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code files**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Configure API endpoint**
Edit `lib/src/core/constants.dart`:
```dart
const String apiBaseUrl = 'http://YOUR_PI_IP:8000';  // Replace with your Pi's IP
const bool useDummyData = false;  // Set to true for testing without hardware
```

5. **Configure Firebase** (Optional, for push notifications)
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Download `google-services.json` (Android) to `android/app/`
- Update `lib/firebase_options.dart` with your Firebase config
- If not using Firebase, the app will skip notification initialization gracefully

### Running the App

**Android**
```bash
flutter run -d android
```

**Web**
```bash
flutter run -d chrome
```

**Desktop** (Windows/Linux/macOS)
```bash
flutter run -d windows  # or linux, macos
```

### Building for Production

**Android APK**
```bash
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

**Web**
```bash
flutter build web --release
```

## 🔧 Configuration

### API Configuration
The app connects to a Raspberry Pi backend. Configure the endpoint in `constants.dart`:

```dart
const String apiBaseUrl = 'http://192.168.1.100:8000';  // Your Pi's local IP
// For testing: Use mock API URL provided in constants.dart
```

### Dummy Data Mode
For development without hardware:
```dart
const bool useDummyData = true;  // Uses mock Postman API
```

### Language Support
Add new languages in `l10n/`:
1. Create `app_<locale>.arb` (e.g., `app_fr.arb`)
2. Run `flutter gen-l10n`
3. Update `supportedLocales` in `main.dart`

## 📊 Features Deep Dive

### Energy Dashboard
- **Real-time Gauge**: Displays current usage with color-coded zones (green/orange/red)
- **Appliance Selector**: Switch between different monitored appliances
- **Energy Impact Scorecard**: Shows average, peak, and total readings
- **AI Insights**: Contextual recommendations based on usage patterns

### History View
- **Interactive Charts**: Zoom and pan through historical data
- **Multiple Time Ranges**: Day, week, and month views
- **Daily Statistics**: Per-day breakdown with min/max/average
- **Trend Analysis**: Visual comparison of usage over time

### Profile Management
- **Multiple Profiles**: Create and switch between user profiles
- **Avatar Support**: Upload custom profile pictures
- **Achievement Tracking**: View unlocked badges and energy score
- **Energy Challenge**: Take quiz to unlock achievements

### Notifications
- **High Usage Alerts**: Get notified when usage exceeds threshold (80W default)
- **Daily Summaries**: Receive end-of-day energy reports
- **Achievement Notifications**: Celebrate milestones

## 🔐 Permissions

### Android
Required permissions in `AndroidManifest.xml`:
- `INTERNET` - API communication
- `POST_NOTIFICATIONS` - Push notifications (Android 13+)
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - Log file downloads
- `CAMERA` - Avatar image capture (optional)

### iOS
Add to `Info.plist`:
- `NSCameraUsageDescription` - For avatar photos
- `NSPhotoLibraryUsageDescription` - For image selection
- `NSMicrophoneUsageDescription` - For voice features (if enabled)

## 🧪 Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test
```

Generate test coverage:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🐛 Troubleshooting

### Common Issues

**1. API Connection Failed**
- Check `constants.dart` has correct Pi IP address
- Ensure Pi is on same network
- Verify API server is running: `curl http://PI_IP:8000/energy`

**2. Build Runner Errors**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**3. Firebase Initialization Failed**
- The app continues without Firebase if initialization fails
- Check Firebase configuration in `firebase_options.dart`
- Ensure `google-services.json` is in `android/app/`

**4. Database Errors on Web**
- Web uses IndexedDB via `sqflite_common_ffi_web`
- Clear browser cache if database corruption occurs
- Check browser console for detailed errors

**5. Notification Permissions Denied**
- App will work without notifications
- Re-enable in device settings > App > Permissions

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Supports notification channels for categorized alerts

### iOS
- Minimum iOS: 12.0
- Requires provisioning profile for physical devices
- Push notifications need Apple Developer account

### Web
- Tested on Chrome, Firefox, Safari
- Service worker required for web push notifications (optional)
- Uses IndexedDB for local storage

### Desktop
- Windows 10+ / macOS 10.14+ / Linux (Ubuntu 18.04+)
- Uses FFI for SQLite on desktop platforms

## 🌍 Localization

Current languages:
- **English (en)**: Default language
- **Chichewa (ny)**: Full translation for Malawi users

To add translations:
1. Copy `l10n/app_en.arb` to `l10n/app_<locale>.arb`
2. Translate all strings
3. Run `flutter gen-l10n`
4. Restart the app

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Syncfusion Flutter**: Beautiful charts and gauges
- **Firebase**: Push notification infrastructure
- **Lottie**: Smooth onboarding animations
- **Flutter Team**: Excellent cross-platform framework

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the Pi scripts README for backend setup

---
