// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Energy Monitor';

  @override
  String get welcome => 'Welcome';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get currentUsage => 'Current Usage';

  @override
  String get energyTimeline => 'Energy Timeline';

  @override
  String get energyProfile => 'Energy Profile';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get refresh => 'Refresh';

  @override
  String get peakUsage => 'Peak Usage';

  @override
  String get averageUsage => 'Average Usage';

  @override
  String get totalReadings => 'Total Readings';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get offlineMode => 'Offline Mode - Using cached data';

  @override
  String get loadingData => 'Loading energy data...';

  @override
  String get energyImpactScorecard => 'Energy Impact Scorecard';

  @override
  String get aiEnergyInsights => 'AI Energy Insights';

  @override
  String get selectAppliance => 'Select Appliance';

  @override
  String get dataRefreshed => 'Data refreshed successfully';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get highUsageAlert => 'High energy usage detected!';

  @override
  String get reduceUsage => 'Consider reducing appliance use';

  @override
  String get energyChallenge => 'Take Energy Challenge';

  @override
  String get downloadLogs => 'Download Log Files';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get achievements => 'Achievements';

  @override
  String get energyScore => 'Energy Score';
}
