# Energy Monitor App

Real-Time Energy Monitoring with Flutter

## Features

- **Real-time Energy Monitoring**: Track your energy consumption in real-time
- **Interactive Dashboard**: Beautiful gauge and chart visualizations
- **Voice Commands**: Use speech-to-text for hands-free operation
- **Offline Support**: Works without internet connection
- **Energy Challenges**: Educational quizzes to learn about energy efficiency
- **Profile Management**: Multiple user profiles with achievements
- **Theme Switching**: Toggle between light and dark modes

## Theme Switching

The app includes a comprehensive theme system that allows users to switch between light and dark modes:

### How to Use
- Tap the theme toggle button (sun/moon icon) in the app bar
- The entire app will instantly switch between light and dark themes
- Theme preference is maintained throughout the app session

### Theme Features
- **Dark Mode**: Deep blue backgrounds with light text for low-light environments
- **Light Mode**: Clean white backgrounds with dark text for bright environments
- **Consistent Styling**: All components adapt to the selected theme
- **Smooth Transitions**: Animated theme switching for better user experience

### Themed Components
- App bar and navigation
- Dashboard cards and gauges
- Charts and graphs
- Text fields and buttons
- Onboarding screens
- Profile pages

## Getting Started

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. Navigate through the onboarding screens and enter your name

4. Use the theme toggle button in the app bar to switch between light and dark modes

## Dependencies

- `provider`: State management for theme switching
- `syncfusion_flutter_gauges`: Energy consumption gauge
- `syncfusion_flutter_charts`: Energy history charts
- `speech_to_text`: Voice command functionality
- `flutter_tts`: Text-to-speech for accessibility
- `lottie`: Animated onboarding screens
- `image_picker`: Profile avatar selection
- `sqflite`: Local data storage
- `http`: API communication

## Architecture

The app uses the Provider pattern for state management, specifically for theme switching. The `ThemeProvider` class manages the current theme state and provides both light and dark theme configurations.
