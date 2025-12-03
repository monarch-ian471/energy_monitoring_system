import 'package:energy_monitor_app/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide Consumer, ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWeb;
import 'src/core/theme/theme_provider.dart';
import 'src/presentation/screens/onboarding_screen.dart';
import 'src/services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Platform check
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/core/error_handler.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue app without Firebase for offline-first design
  }

  try {
    if (!kIsWeb) {
      await NotificationService().initialize();
    } else {
      // Web notifications require service worker (optional)
      debugPrint('Web notifications require service worker setup');
    }
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('Running on Web - using sqflite_common_ffi_web');
  } else {
    // Desktop/Mobile: Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('Running on Desktop/Mobile - using sqflite_ffi');
  }

  runApp(
    const ProviderScope(child: EnergyMonitorApp()),
  );
}

class EnergyMonitorApp extends StatelessWidget {
  const EnergyMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: "Energy Monitoring",
            theme: themeProvider.themeData,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ny', ''), // Chichewa
            ],
            home: const OnboardingScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
