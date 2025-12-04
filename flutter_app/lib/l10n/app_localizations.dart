import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ny.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ny')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Energy Monitor'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @currentUsage.
  ///
  /// In en, this message translates to:
  /// **'Current Usage'**
  String get currentUsage;

  /// No description provided for @energyTimeline.
  ///
  /// In en, this message translates to:
  /// **'Energy Timeline'**
  String get energyTimeline;

  /// No description provided for @energyProfile.
  ///
  /// In en, this message translates to:
  /// **'Energy Profile'**
  String get energyProfile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @peakUsage.
  ///
  /// In en, this message translates to:
  /// **'Peak Usage'**
  String get peakUsage;

  /// No description provided for @averageUsage.
  ///
  /// In en, this message translates to:
  /// **'Average Usage'**
  String get averageUsage;

  /// No description provided for @totalReadings.
  ///
  /// In en, this message translates to:
  /// **'Total Readings'**
  String get totalReadings;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode - Using cached data'**
  String get offlineMode;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading energy data...'**
  String get loadingData;

  /// No description provided for @energyImpactScorecard.
  ///
  /// In en, this message translates to:
  /// **'Energy Impact Scorecard'**
  String get energyImpactScorecard;

  /// No description provided for @aiEnergyInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Energy Insights'**
  String get aiEnergyInsights;

  /// No description provided for @selectAppliance.
  ///
  /// In en, this message translates to:
  /// **'Select Appliance'**
  String get selectAppliance;

  /// No description provided for @dataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed successfully'**
  String get dataRefreshed;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @highUsageAlert.
  ///
  /// In en, this message translates to:
  /// **'High energy usage detected!'**
  String get highUsageAlert;

  /// No description provided for @reduceUsage.
  ///
  /// In en, this message translates to:
  /// **'Consider reducing appliance use'**
  String get reduceUsage;

  /// No description provided for @energyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Take Energy Challenge'**
  String get energyChallenge;

  /// No description provided for @downloadLogs.
  ///
  /// In en, this message translates to:
  /// **'Download Log Files'**
  String get downloadLogs;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @energyScore.
  ///
  /// In en, this message translates to:
  /// **'Energy Score'**
  String get energyScore;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Energy Monitor'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your gateway to smart energy.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Master Your Power'**
  String get onboardingMasterTitle;

  /// No description provided for @onboardingMasterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control every watt with ease.'**
  String get onboardingMasterSubtitle;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track & Thrive'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See your energy story unfold.'**
  String get onboardingTrackSubtitle;

  /// No description provided for @onboardingFutureTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Energy, Reimagined'**
  String get onboardingFutureTitle;

  /// No description provided for @onboardingFutureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline-ready, future-proof.'**
  String get onboardingFutureSubtitle;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterEnergyMonitor.
  ///
  /// In en, this message translates to:
  /// **'Enter the Energy Monitor'**
  String get enterEnergyMonitor;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @switchToChichewa.
  ///
  /// In en, this message translates to:
  /// **'Switch to Chichewa'**
  String get switchToChichewa;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChanged;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ny'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ny':
      return AppLocalizationsNy();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
