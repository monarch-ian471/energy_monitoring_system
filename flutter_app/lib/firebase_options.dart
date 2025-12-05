import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // WEB CONFIGURATION (with fallback for missing env vars)
  static FirebaseOptions get web {
    // Use environment variables with safe fallbacks
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    final appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
    final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'];

    // Validate required fields
    if (apiKey.isEmpty || projectId.isEmpty || appId.isEmpty) {
      throw Exception(
        'Firebase configuration missing! Ensure FIREBASE_API_KEY, '
        'FIREBASE_PROJECT_ID, and FIREBASE_APP_ID are set in environment variables.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKey,
      authDomain: authDomain,
      projectId: projectId,
      storageBucket: storageBucket,
      messagingSenderId: messagingSenderId,
      appId: appId,
      measurementId: measurementId,
    );
  }

  // ANDROID CONFIGURATION
  static FirebaseOptions get android {
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }
}