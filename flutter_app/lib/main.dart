import 'package:energy_monitor_app/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide Consumer, ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/presentation/screens/onboarding_screen.dart';
import 'src/services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Platform check
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // FFI for web
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized

  await Firebase.initializeApp(); // Initialize Firebase

  await NotificationService().initialize(); // Initialize notifications

  if (kIsWeb) {
    databaseFactory =
        databaseFactoryFfi; // Sets factory for web SQLite (browser-based)
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
          );
        },
      ),
    );
  }
}
