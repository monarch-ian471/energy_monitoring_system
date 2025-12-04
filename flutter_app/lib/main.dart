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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'src/presentation/providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'src/core/fallback_localizations_delegate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('.env file loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    debugPrint('AI insights will use fallback logic');
  }

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('Web database initialized');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  try {
    if (!kIsWeb) {
      await NotificationService().initialize();
      debugPrint('Notifications initialized');
    } else {
      debugPrint('Web notifications require service worker setup');
    }
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(
    const ProviderScope(child: EnergyMonitorApp()),
  );
}

class EnergyMonitorApp extends StatelessWidget {
  const EnergyMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: "Energy Monitoring",
            theme: themeProvider.themeData,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalisationsDelegate(),
              FallbackCupertinoLocalisationsDelegate(),
              GlobalWidgetsLocalizations.delegate,
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
