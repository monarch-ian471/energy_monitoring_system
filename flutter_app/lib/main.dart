import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/presentation/screens/onboarding_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Platform check
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// FFI for web

void main() {
  if (kIsWeb) {
    databaseFactory =
        databaseFactoryFfi; // Fixed: Sets factory for web SQLite (browser-based)
  }
  runApp(const EnergyMonitorApp());
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
            home: const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
