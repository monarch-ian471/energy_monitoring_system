import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'energy_dashboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String ownerName = "";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildOnboardingPage(
                      l10n.onboardingWelcomeTitle,
                      l10n.onboardingWelcomeSubtitle,
                      "assets/animations/energy_welcome.json",
                      Colors.green,
                      themeProvider),
                  _buildOnboardingPage(
                      l10n.onboardingMasterTitle,
                      l10n.onboardingMasterSubtitle,
                      "assets/animations/master_power.json",
                      const Color.fromARGB(255, 18, 121, 206),
                      themeProvider),
                  _buildOnboardingPage(
                      l10n.onboardingTrackTitle,
                      l10n.onboardingTrackSubtitle,
                      "assets/animations/track_thrive.json",
                      Colors.teal,
                      themeProvider),
                  _buildOnboardingPage(
                      l10n.onboardingFutureTitle,
                      l10n.onboardingFutureSubtitle,
                      "assets/animations/energy_reimagined.json",
                      Colors.cyan,
                      themeProvider,
                      isLast: true),
                ],
              ),
              // Language toggle button
              if (_currentPage == 0)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 20,
                  child: OutlinedButton.icon(
                    onPressed: () => localeProvider.toggleLocale(),
                    icon: Text(
                      localeProvider.currentLanguageFlag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    label: Text(
                      l10n.switchToChichewa,
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) => _buildDot(index)),
                    ),
                    const SizedBox(height: 20),
                    if (_currentPage == 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (value) => ownerName = value,
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? const Color(0xFFE0E7FF)
                                    : const Color(0xFF2C3E50),
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.enterYourName,
                                hintStyle: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                                filled: true,
                                fillColor: themeProvider.isDarkMode
                                    ? const Color(0xFF2A3555)
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EnergyDashboard(initialName: ownerName)
                                            as Widget,
                                  ),
                                );
                              },
                              child: Text(l10n.enterEnergyMonitor),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                        child: Text(l10n.next),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnboardingPage(String title, String description,
      String lottieUrl, Color color, ThemeProvider themeProvider,
      {bool isLast = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen =
            constraints.maxHeight < 600 || constraints.maxWidth < 350;
        return SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withAlpha(204),
                  themeProvider.isDarkMode
                      ? const Color(0xFF0A1F33)
                      : const Color(0xFFF5F5F5)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.network(lottieUrl,
                    width: isSmallScreen ? 180 : 300,
                    height: isSmallScreen ? 180 : 300,
                    fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontSize: isSmallScreen ? 18 : 24,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : const Color(0xFF2C3E50))),
                const SizedBox(height: 10),
                Text(description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.grey[700],
                        fontSize: isSmallScreen ? 14 : 18)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _currentPage == index ? 14 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF4CAF50)
            : Colors.grey.withAlpha(128),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
