// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for all platforms
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // case TargetPlatform.iOS:
      //   return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // WEB CONFIGURATION (paste your firebaseConfig here)
  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyBZB31ssPafqxSPPGIbT3knIP_xPa0aDM8",
      authDomain: "energymonitor-3cd28.firebaseapp.com",
      projectId: "energymonitor-3cd28",
      storageBucket: "energymonitor-3cd28.firebasestorage.app",
      messagingSenderId: "1043917657336",
      appId: "1:1043917657336:web:ce9389b2863e3cdc67170d",
      measurementId: "G-92B8S492KD");

  // ANDROID CONFIGURATION (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA85G4fc_Zq4zMYDTGxYRkpGi6j6QraWzQ',
    appId: '1:1043917657336:android:d7028e562069cd3767170d',
    messagingSenderId: '1043917657336',
    projectId: 'energymonitor-3cd28',
    storageBucket: 'energymonitor-3cd28.firebasestorage.app',
  );

  // iOS CONFIGURATION (from GoogleService-Info.plist)
  // static const FirebaseOptions ios = FirebaseOptions(
  //   apiKey: 'AIza...YOUR_IOS_API_KEY',
  //   appId: '1:123456789:ios:ghi789',
  //   messagingSenderId: '123456789',
  //   projectId: 'your-project-id',
  //   storageBucket: 'your-app.appspot.com',
  //   iosBundleId: 'com.iankatengeza.energy_monitor_app',
  // );
}
