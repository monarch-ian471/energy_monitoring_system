import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Toggle for dummy data (uses Postman mock server when true)
const bool useDummyData = false;
// Configurable API base URL (switches to mock server for dummy data)
const String apiBaseUrl = useDummyData
    ? 'https://5ed82b73-5ed4-4c32-99b2-47b88a17336d.mock.pstmn.io'
    : 'http://localhost:8000';

// Theme Provider (Managing and switching between dark and light theme)
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get themeData {
    if (_isDarkMode) {
      return _darkTheme;
    } else {
      return _lightTheme;
    }
  }

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFF0A1F33),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFE0E7FF), fontSize: 16),
      headlineSmall: TextStyle(
          color: Color(0xFF4CAF50),
          fontWeight: FontWeight.bold,
          fontSize: 24),
      headlineMedium: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
    ),
    cardColor: const Color(0xFF1E2A44),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        elevation: 8,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A1F33),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE0E7FF)),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E2A44),
      selectedItemColor: Color(0xFF4CAF50),
      unselectedItemColor: Colors.white70,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF4CAF50);
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF4CAF50).withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.5);
      }),
    ),
  );

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF2C3E50), fontSize: 16),
      headlineSmall: TextStyle(
          color: Color(0xFF4CAF50),
          fontWeight: FontWeight.bold,
          fontSize: 24),
      headlineMedium: TextStyle(
          color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 32),
    ),
    cardColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        elevation: 4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      elevation: 2,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF4CAF50);
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF4CAF50).withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.5);
      }),
    ),
  );
}

void main() {
  runApp(const EnergyMonitorApp());
}

// Dynamic theming (dark/light Mode) using provider for state management and launches onboarding screen as the first page
class EnergyMonitorApp extends StatelessWidget {
  const EnergyMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Energy Monitoring',
            theme: themeProvider.themeData,
            home: const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

// Onboarding Screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

// State class for OnboardingScreen widget (Manage the onboarding flow, user's name collection and transition)
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String ownerName = "";

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildOnboardingPage(
                      "Welcome to Energy Monitor",
                      "Your gateway to smart energy.",
                      "assets/animations/energy_welcome.json",
                      Colors.green,
                      themeProvider),
                  _buildOnboardingPage(
                      "Master Your Power",
                      "Control every watt with ease.",
                      "assets/animations/master_power.json",
                      const Color.fromARGB(255, 18, 121, 206),
                      themeProvider),
                  _buildOnboardingPage(
                      "Track & Thrive",
                      "See your energy story unfold.",
                      "assets/animations/track_thrive.json",
                      Colors.teal,
                      themeProvider),
                  _buildOnboardingPage(
                      "Your Energy, Reimagined",
                      "Offline-ready, future-proof.",
                      "assets/animations/energy_reimagined.json",
                      Colors.cyan,
                      themeProvider,
                      isLast: true),
                ],
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
                                hintText: "Enter your name",
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
                                        EnergyDashboard(initialName: ownerName),
                                  ),
                                );
                              },
                              child: const Text("Enter the Energy Monitor"),
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
                        child: const Text("Next"),
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

  Widget _buildOnboardingPage(
      String title, String description, String lottieUrl, Color color,
      ThemeProvider themeProvider, {bool isLast = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600 || constraints.maxWidth < 350;
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
                    width: isSmallScreen ? 180 : 300, height: isSmallScreen ? 180 : 300, fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontSize: isSmallScreen ? 18 : 24, color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF2C3E50))),
                const SizedBox(height: 10),
                Text(description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700], 
                      fontSize: isSmallScreen ? 14 : 18
                    )),
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

// Energy Challenges Sceen
class EnergyChallengeScreen extends StatefulWidget {
  final Function(List<String> achievements, double score) onAchievementsEarned;
  const EnergyChallengeScreen({Key? key, required this.onAchievementsEarned})
      : super(key: key);

  @override
  State<EnergyChallengeScreen> createState() => _EnergyChallengeScreenState();
}

//State class for EnergyChallengeScreen (Got bored, and added a challenge game for the user to go through)
class _EnergyChallengeScreenState extends State<EnergyChallengeScreen> {
  final List<Map<String, dynamic>> _questions = [
    {
      "question":
          "What is the most energy-efficient time to use heavy appliances?",
      "options": ["During peak hours", "During off-peak hours", "At noon", "Anytime"],
      "answer": 1,
    },
    {
      "question": "Which bulb uses the least energy?",
      "options": ["Incandescent", "Halogen", "LED", "CFL"],
      "answer": 2,
    },
    {
      "question": "What does a smart meter do?",
      "options": ["Measures water usage", "Measures energy usage in real time", "Cools your house", "Charges your phone"],
      "answer": 1,
    },
    {
      "question": "What is a phantom load?",
      "options": ["Energy used by appliances when off", "Energy from solar panels", "Wind energy", "None of the above"],
      "answer": 0,
    },
    {
      "question": "Which is a renewable energy source?",
      "options": ["Coal", "Natural Gas", "Solar", "Oil"],
      "answer": 2,
    },
    {
      "question": "What is the best way to reduce AC energy use?",
      "options": ["Open windows during the day", "Set thermostat higher", "Run all day", "Block vents"],
      "answer": 1,
    },
    {
      "question": "What is net metering?",
      "options": ["Paying for internet", "Selling excess solar energy back to the grid", "Measuring water", "None of the above"],
      "answer": 1,
    },
    {
      "question": "Which appliance uses the most energy at home?",
      "options": ["Refrigerator", "TV", "Microwave", "Washing Machine"],
      "answer": 0,
    },
    {
      "question": "What is the benefit of unplugging chargers?",
      "options": ["Saves energy", "Makes phone charge faster", "No benefit", "Damages charger"],
      "answer": 0,
    },
    {
      "question": "What is the main cause of peak energy demand?",
      "options": ["People sleeping", "Simultaneous use of many appliances", "Rainy weather", "Solar panels"],
      "answer": 1,
    },
    {
      "question": "Which of these is NOT a renewable energy source?",
      "options": ["Wind", "Hydro", "Natural Gas", "Solar"],
      "answer": 2,
    },
    {
      "question": "What does Energy Star label mean?",
      "options": ["High energy use", "Energy efficient product", "Expensive product", "Old product"],
      "answer": 1,
    },
    {
      "question": "What is the best way to save energy with lighting?",
      "options": ["Use more lamps", "Use LED bulbs", "Leave lights on", "Use candles"],
      "answer": 1,
    },
    {
      "question": "What is a solar inverter?",
      "options": ["Converts DC to AC", "Stores energy", "Cools solar panels", "Measures sunlight"],
      "answer": 0,
    },
    {
      "question": "What is the best temperature to set your fridge?",
      "options": ["0°C", "4°C (39°F)", "10°C", "20°C"],
      "answer": 1,
    },
    {
      "question": "Which is a peak saving behavior?",
      "options": ["Run dishwasher at 7pm", "Run dishwasher at 11pm", "Run dishwasher at 6pm", "Run dishwasher at 8am"],
      "answer": 1,
    },
    {
      "question": "What is the main benefit of solar panels?",
      "options": ["Lower energy bills", "More heat", "More noise", "None"],
      "answer": 0,
    },
    {
      "question": "What is a kilowatt-hour?",
      "options": ["A measure of power", "A measure of energy", "A measure of time", "A measure of voltage"],
      "answer": 1,
    },
    {
      "question": "Which is a solar energy achievement?",
      "options": ["Using solar panels", "Using more gas", "Using more coal", "None"],
      "answer": 0,
    },
    {
      "question": "What is the best way to reduce standby power?",
      "options": ["Unplug devices", "Use more devices", "Leave everything plugged in", "Use old appliances"],
      "answer": 0,
    },
  ];

  int _currentQuestion = 0;
  int _score = 0;
  List<String> _earnedAchievements = [];

  void _answer(int selected) {
    final correct = _questions[_currentQuestion]['answer'] as int;
    if (selected == correct) _score++;
    setState(() {
      _currentQuestion++;
    });
    if (_currentQuestion == _questions.length) {
      _tallyAchievements();
    }
  }

  void _tallyAchievements() {
    _earnedAchievements.clear();
    if (_score >= 15) _earnedAchievements.add("Eco Warrior");
    if (_score >= 10) _earnedAchievements.add("Peak Saver");
    if (_score >= 5) _earnedAchievements.add("Solar Star");
    final double percent = _score / _questions.length;
    widget.onAchievementsEarned(_earnedAchievements, percent);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Challenge Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You scored $_score out of ${_questions.length}."),
            const SizedBox(height: 10),
            const Text("Achievements Earned:"),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              children: _earnedAchievements.isEmpty
                  ? [const Text("None")]
                  : _earnedAchievements
                      .map((a) => Chip(label: Text(a)))
                      .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Return"),
          ),
        ],
      ),
    ).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion >= _questions.length) {
      return const Center(child: Text("Challenge Complete!"));
    }
    final q = _questions[_currentQuestion];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Energy Challenge"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 20),
            Text(
              "Question ${_currentQuestion + 1} of ${_questions.length}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              q['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              (q['options'] as List).length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  onPressed: () => _answer(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(q['options'][i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Energy Dashboard
class EnergyDashboard extends StatefulWidget {
  final String initialName;
  const EnergyDashboard({Key? key, required this.initialName})
      : super(key: key);

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

//State class for EnergyDashboard 
class _EnergyDashboardState extends State<EnergyDashboard>
    with SingleTickerProviderStateMixin {
  String currentWatts = "0";
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> historicalData = [];
  List<Map<String, dynamic>> dailyStats = [];
  String ownerName = "";
  Database? database;
  bool advancedMode = false;
  bool _isFetching = true; // Start with fetching true to show loading
  bool _isLoadingHistorical = false; // Add loading state for historical data
  int _currentIndex = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animationController;
  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    ownerName = widget.initialName;
    _initDatabase();
    _fetchData().then((_) {
      if (mounted) setState(() => _isFetching = false); // Update only if mounted
    }).catchError((e) {
      print('Fetch Error: $e');
      if (mounted) setState(() => _isFetching = false); // Handle error state
    });
    
    // Also load historical data from logs
    _fetchHistoricalData(days: 7).catchError((e) {
      print('Historical data init error: $e');
    });
    
    _initSpeech();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'energy_data.db');
    database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE cache(id INTEGER PRIMARY KEY, timestamp TEXT, watts REAL)");
      },
      version: 1,
    );
  }

  void _initSpeech() async {
    try {
      await _speech.initialize();
      
      // Only initialize TTS on non-web platforms
      if (!kIsWeb) {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.speak(
            "Welcome to Energy Monitor, $ownerName. Let's optimize your energy!");
      }
    } catch (e) {
      print('Speech/TTS initialization error: $e');
    }
  }

  static Future<dynamic> _fetchDataIsolate(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {'error': 'Invalid response format'};
      } catch (e) {
        return {'error': 'Failed to parse JSON: $e'};
      }
    }
    return {'error': 'Failed to fetch data from $url, status: ${response.statusCode}'};
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        compute(_fetchDataIsolate, '$apiBaseUrl/energy'),
        compute(_fetchDataIsolate, '$apiBaseUrl/energy/history'),
      ]);

      final latest = results[0];
      final historyData = results[1];

      print('API Response /energy: $latest'); // Debug log
      print('API Response /history: $historyData'); // Debug log

      if (latest is! Map<String, dynamic> || latest.containsKey('error')) {
        throw Exception('Invalid or error response from /energy: $latest');
      }
      if (historyData is! Map<String, dynamic> || historyData.containsKey('error')) {
        throw Exception('Invalid or error response from history: $historyData');
      }

      if (!latest.containsKey('watts')) {
        throw Exception('No watts data in /energy response: $latest');
      }

      setState(() {
        currentWatts = (latest['watts'] as num).toStringAsFixed(2);
        history = (historyData['data'] as List?)?.map<Map<String, dynamic>>((item) {
          if (item is Map<String, dynamic> && item.containsKey('watts') && item.containsKey('timestamp')) {
            var watts = item['watts'];
            if (watts is int) watts = watts.toDouble();
            return {'timestamp': item['timestamp'], 'watts': watts};
          }
          return {};
        }).where((e) => e.isNotEmpty).toList() ?? [];
      });

      await database?.delete('cache');
      for (var item in history) {
        await database?.insert('cache', {'timestamp': item['timestamp'], 'watts': item['watts']});
      }
    } catch (e) {
      print('API Error: $e'); // Debug log
      final cachedData = await database?.query('cache', orderBy: 'timestamp DESC', limit: 24);
      if (cachedData != null) {
        setState(() {
          history = cachedData
              .map((e) => {
                    'timestamp': e['timestamp'] as String,
                    'watts': e['watts'] is int ? (e['watts'] as int).toDouble() : e['watts'] as double,
                  })
              .toList();
          currentWatts = history.isNotEmpty ? history.first['watts'].toStringAsFixed(2) : "Offline";
        });
      } else {
        // Fallback to dummy data if no cache
        setState(() {
          history = [
            {'timestamp': DateTime.now().toIso8601String(), 'watts': 00.0}, // Match API response
          ];
          currentWatts = "00.00"; // Match API response
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _generatePdfReport() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("PDF Report Generated!")));
  }

  Future<void> _pickAvatar() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() => _avatarImage = File(pickedFile.path));
    }
  }

  Future<void> _fetchHistoricalData({int days = 7}) async {
    if (mounted) setState(() => _isLoadingHistorical = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/logs/historical-data?days=$days'));
      print('API Response /history: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        if (data.containsKey('data') && data.containsKey('daily_stats')) {
          setState(() {
            // Update both historical data and daily stats
            historicalData = List<Map<String, dynamic>>.from(data['data']);
            dailyStats = List<Map<String, dynamic>>.from(data['daily_stats']);
            
            // Convert log data format to match the expected chart format
            history = historicalData.map<Map<String, dynamic>>((item) {
              return {
                'timestamp': item['timestamp'],
                'watts': item['watts'] is int ? (item['watts'] as int).toDouble() : item['watts'] as double,
              };
            }).toList();
            
            // Update current watts to the latest reading if available
            if (history.isNotEmpty) {
              currentWatts = history.first['watts'].toStringAsFixed(2);
            }
          });
          
          // Cache the new data
          await database?.delete('cache');
          for (var item in history) {
            await database?.insert('cache', {'timestamp': item['timestamp'], 'watts': item['watts']});
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Loaded ${history.length} historical readings from logs"))
          );
        } else if (data.containsKey('error')) {
          // Handle error response from mock server
          print('API Error: ${data['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("API Error: ${data['error']}"))
          );
        } else {
          // Handle unexpected response format
          print('API Error: Invalid response format');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid response format from server"))
          );
        }
      } else {
        throw Exception('Failed to fetch historical data: ${response.statusCode}');
      }
    } catch (e) {
      print('Historical data fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading historical data: $e"))
      );
    } finally {
      if (mounted) setState(() => _isLoadingHistorical = false);
    }
  }

  Future<void> _downloadLogFile(String logType) async {
    try {
      // For web platform, create a download link
      if (kIsWeb) {
        final response = await http.get(Uri.parse('$apiBaseUrl/logs/download/$logType'));
        if (response.statusCode == 200) {
          // For web, we'll use a simple approach - show a message with the data
          // In a real implementation, you'd use dart:html for proper file download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Log data received (${response.bodyBytes.length} bytes). Web download feature coming soon!"),
              duration: const Duration(seconds: 3),
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to download log file"))
          );
        }
        return;
      }

      // For mobile platforms, use storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission required to download logs"))
          );
          return;
        }
      }

      final response = await http.get(Uri.parse('$apiBaseUrl/logs/download/$logType'));
      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not access storage directory"))
          );
          return;
        }
        
        final file = File('${directory.path}/$logType.log');
        await file.writeAsBytes(response.bodyBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Log file downloaded to: ${file.path}"))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download log file"))
        );
      }
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download error: $e"))
      );
    }
  }

  Future<void> _showLogDownloadDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Download Log Files"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.monitor),
              title: const Text("Energy Monitor Log"),
              subtitle: const Text("Historical energy readings"),
              onTap: () {
                Navigator.pop(context);
                _downloadLogFile("energy-monitor");
              },
            ),
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text("API Log"),
              subtitle: const Text("API request history"),
              onTap: () {
                Navigator.pop(context);
                _downloadLogFile("api");
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAllData() async {
    setState(() => _isFetching = true);
    try {
      await Future.wait([
        _fetchData(),
        _fetchHistoricalData(days: 7),
      ]);
    } catch (e) {
      print('Refresh error: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? "Good Morning"
        : hour < 17
            ? "Good Afternoon"
            : "Good Evening";

    Widget getCurrentPage() {
      if (_isFetching) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
      }
      switch (_currentIndex) {
        case 0:
          return _buildHomePage(greeting);
        case 1:
          return _buildHistoryPage();
        case 2:
          return _buildProfilePage();
        default:
          return _buildHomePage(greeting);
      }
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                  'https://img.icons8.com/ios-filled/50/ffffff/lightning-bolt.png',
                  width: 40,
                  height: 40),
            ),
            title: const Text("Energy Monitor"),
            actions: [
              IconButton(
                  icon: const Icon(Icons.download), onPressed: _showLogDownloadDialog),
              // Theme Toggle Button
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeProvider.isDarkMode ? Colors.yellow : Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              ),
              Switch(
                  value: advancedMode,
                  activeColor: const Color(0xFF4CAF50),
                  onChanged: (value) => setState(() => advancedMode = value)),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: getCurrentPage(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _isFetching ? null : () => _refreshAllData(),
            backgroundColor: const Color(0xFF4CAF50),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Transform.rotate(
                angle: _animationController.value * 2 * 3.14159,
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomePage(String greeting) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 400 ? 12.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: constraints.maxWidth,
                  padding: EdgeInsets.all(constraints.maxWidth < 400 ? 10 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50), 
                        themeProvider.isDarkMode 
                            ? const Color(0xFF2A3555) 
                            : const Color(0xFFE8F5E8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: themeProvider.isDarkMode 
                              ? Colors.black26 
                              // ignore: deprecated_member_use
                              : Colors.grey.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$greeting, $ownerName!",
                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: constraints.maxWidth < 400 ? 20 : 32)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Current Usage",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(fontSize: constraints.maxWidth < 400 ? 14 : 20, color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700])),
                          Text("$currentWatts W",
                              style: TextStyle(
                                  fontSize: constraints.maxWidth < 400 ? 18 : 28,
                                  color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          height: constraints.maxWidth < 400 ? 120 : 200,
                          width: constraints.maxWidth < 400 ? 120 : 200,
                          child: SfRadialGauge(
                            axes: [
                              RadialAxis(
                                minimum: 0,
                                maximum: 100,
                                ranges: [
                                  GaugeRange(
                                      startValue: 0,
                                      endValue: 33,
                                      color: Colors.green),
                                  GaugeRange(
                                      startValue: 33,
                                      endValue: 66,
                                      color: Colors.orange),
                                  GaugeRange(
                                      startValue: 66,
                                      endValue: 100,
                                      color: Colors.red),
                                ],
                                pointers: [
                                  NeedlePointer(
                                      value: double.tryParse(currentWatts) ?? 0,
                                      enableAnimation: true)
                                ],
                                annotations: [
                                  GaugeAnnotation(
                                    widget: Text('$currentWatts W',
                                        style: TextStyle(
                                            fontSize: constraints.maxWidth < 400 ? 14 : 20,
                                            color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                                            fontWeight: FontWeight.bold)),
                                    angle: 90,
                                    positionFactor: 0.5,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text("Energy Impact Scorecard",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: constraints.maxWidth < 400 ? 16 : 24)),
                Container(
                  height: constraints.maxWidth > 600 ? 200 : (constraints.maxWidth < 400 ? 100 : 140),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50), 
                        themeProvider.isDarkMode 
                            ? const Color(0xFF0A1F33) 
                            : const Color(0xFFE8F5E8)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: Card(
                              color: Colors.green[700],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Text("Average Usage", style: TextStyle(color: Colors.white)),
                                    Text("${_calculateAverageUsage().toStringAsFixed(1)} W",
                                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Card(
                              color: Colors.blue[700],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Text("Peak Usage", style: TextStyle(color: Colors.white)),
                                    Text("${_calculatePeakUsage().toStringAsFixed(1)} W",
                                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Card(
                              color: Colors.orange[700],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Text("Total Readings", style: TextStyle(color: Colors.white)),
                                    Text("${_getTotalReadings()}",
                                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ExpansionTile(
                  title: Text("AI Energy Insights",
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: constraints.maxWidth < 400 ? 16 : 24)),
                  collapsedBackgroundColor: themeProvider.isDarkMode 
                      ? const Color(0xFF1E2A44) 
                      : Colors.white,
                  backgroundColor: themeProvider.isDarkMode 
                      ? const Color(0xFF2A3555) 
                      : Colors.grey[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<String>(
                        future: AIEnergyInsights.getEnergyInsight(
                          historicalData.isNotEmpty ? historicalData : history,
                          double.tryParse(currentWatts) ?? 0.0
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 10),
                                Text("Analyzing your energy data..."),
                              ],
                            );
                          }
                          
                          return Text(
                            snapshot.data ?? "Unable to generate insights at this time.",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (advancedMode)
                  ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("AR Mode Coming Soon!"))),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Launch AR View"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods for Energy Impact Scorecard
  double _calculateAverageUsage() {
    List<Map<String, dynamic>> dataToUse = historicalData.isNotEmpty ? historicalData : history;
    if (dataToUse.isEmpty) return 0.0;
    
    double total = dataToUse.fold<double>(0.0, (double sum, item) {
      final watts = item['watts'];
      return sum + _safeWattsToDouble(watts);
    });
    
    return total / dataToUse.length;
  }

  double _calculatePeakUsage() {
    List<Map<String, dynamic>> dataToUse = historicalData.isNotEmpty ? historicalData : history;
    if (dataToUse.isEmpty) return 0.0;
    
    return dataToUse.fold<double>(0.0, (double max, item) {
      final watts = item['watts'];
      double wattsValue = _safeWattsToDouble(watts);
      return wattsValue > max ? wattsValue : max;
    });
  }

  int _getTotalReadings() {
    List<Map<String, dynamic>> dataToUse = historicalData.isNotEmpty ? historicalData : history;
    return dataToUse.length;
  }

  // Helper function to safely convert watts to double
  double _safeWattsToDouble(dynamic watts) {
    if (watts is int) return watts.toDouble();
    if (watts is double) return watts;
    if (watts is String) return double.tryParse(watts) ?? 0.0;
    return 0.0;
  }

  Widget _buildHistoryPage() {
    // Use historical data from logs if available, otherwise fall back to basic history
    List<Map<String, dynamic>> chartData = historicalData.isNotEmpty ? historicalData : history;
    
    // Sort data by timestamp ascending for proper chart display
    List<Map<String, dynamic>> sortedData = List.from(chartData);
    sortedData.sort((a, b) {
      try {
        return DateTime.parse(a['timestamp'])
            .compareTo(DateTime.parse(b['timestamp']));
      } catch (_) {
        return 0;
      }
    });

    // Prepare a line from 0 to currentWatts for the graphical line
    double currentWattsValue = 0.0;
    try {
      currentWattsValue = double.tryParse(currentWatts) ?? 0.0;
    } catch (_) {
      currentWattsValue = 0.0;
    }

    // The x-axis for this line will be from the earliest to the latest timestamp
    DateTime? minTime, maxTime;
    if (sortedData.isNotEmpty) {
      try {
        minTime = DateTime.parse(sortedData.first['timestamp']);
        maxTime = DateTime.parse(sortedData.last['timestamp']);
      } catch (_) {
        minTime = DateTime.now();
        maxTime = DateTime.now();
      }
    } else {
      minTime = DateTime.now();
      maxTime = DateTime.now();
    }

    // If minTime == maxTime, add 1 hour to maxTime to avoid chart errors
    if (minTime == maxTime) {
      maxTime = minTime.add(const Duration(hours: 1));
    }

    // Data for the graphical line from 0 to currentWatts
    final List<Map<String, dynamic>> zeroToCurrentLine = [
      {
        'timestamp': minTime.toIso8601String(),
        'watts': 0.0,
      },
      {
        'timestamp': maxTime.toIso8601String(),
        'watts': currentWattsValue,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final chartHeight = isSmallScreen
            ? 220.0
            : constraints.maxHeight > 500
                ? 350.0
                : 250.0;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Energy Timeline",
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: isSmallScreen ? 16 : 24)),
                  ElevatedButton.icon(
                    onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 7),
                    icon: _isLoadingHistorical 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.history),
                    label: _isLoadingHistorical 
                        ? const Text("Loading...")
                        : const Text("Load Data"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (historicalData.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Showing log data (${sortedData.length} readings)",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (dailyStats.isNotEmpty) ...[
                Text("Daily Statistics (Last 7 Days)",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: isSmallScreen ? 16 : 24)),
                const SizedBox(height: 10),
                if (isSmallScreen)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dailyStats.map((stat) => SizedBox(
                      width: 120,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stat['date'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Avg: ${(stat['avg_watts'] as num).toStringAsFixed(1)} W",
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              Text(
                                "Max: ${(stat['max_watts'] as num).toStringAsFixed(1)} W",
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              Text(
                                "Min: ${(stat['min_watts'] as num).toStringAsFixed(1)} W",
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.hardEdge,
                      itemCount: dailyStats.length,
                      itemBuilder: (context, index) {
                        final stat = dailyStats[index];
                        return SizedBox(
                          width: 140,
                          child: Card(
                            margin: const EdgeInsets.only(right: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    stat['date'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Avg: ${(stat['avg_watts'] as num).toStringAsFixed(1)} W",
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                  Text(
                                    "Max: ${(stat['max_watts'] as num).toStringAsFixed(1)} W",
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                  Text(
                                    "Min: ${(stat['min_watts'] as num).toStringAsFixed(1)} W",
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                height: chartHeight,
                child: _isLoadingHistorical
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF4CAF50)),
                            SizedBox(height: 16),
                            Text("Loading historical data from logs...",
                                style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : sortedData.isNotEmpty
                        ? SfCartesianChart(
                            primaryXAxis: DateTimeAxis(
                              dateFormat: DateFormat.MMMd().add_Hm(),
                              intervalType: DateTimeIntervalType.hours,
                              majorGridLines: const MajorGridLines(width: 0.5),
                            ),
                            primaryYAxis: NumericAxis(
                              title: AxisTitle(text: "Watts"),
                              majorGridLines: const MajorGridLines(width: 0.5),
                            ),
                            series: [
                              // Main energy history spline
                              SplineSeries<Map<String, dynamic>, DateTime>(
                                dataSource: sortedData,
                                xValueMapper: (data, _) {
                                  try {
                                    return DateTime.parse(data['timestamp']);
                                  } catch (e) {
                                    return DateTime.now(); // Fallback to current time if parsing fails
                                  }
                                },
                                yValueMapper: (data, _) {
                                  final watts = data['watts'];
                                  if (watts is int) return watts.toDouble();
                                  if (watts is double) return watts;
                                  if (watts is String) return double.tryParse(watts) ?? 0.0;
                                  return 0.0; // Default to 0 if no valid watts
                                },
                                color: const Color(0xFF4CAF50),
                                animationDuration: 1000,
                                enableTooltip: true,
                                markerSettings: const MarkerSettings(isVisible: true),
                                name: "Energy Usage",
                              ),
                              // Graphical line from 0 to currentWatts
                              LineSeries<Map<String, dynamic>, DateTime>(
                                dataSource: zeroToCurrentLine,
                                xValueMapper: (data, _) {
                                  try {
                                    return DateTime.parse(data['timestamp']);
                                  } catch (e) {
                                    return DateTime.now();
                                  }
                                },
                                yValueMapper: (data, _) {
                                  final watts = data['watts'];
                                  if (watts is int) return watts.toDouble();
                                  if (watts is double) return watts;
                                  if (watts is String) return double.tryParse(watts) ?? 0.0;
                                  return 0.0;
                                },
                                color: Colors.orange,
                                width: 3,
                                dashArray: <double>[6, 3],
                                markerSettings: const MarkerSettings(isVisible: false),
                                name: "Current Watts Line",
                              ),
                            ],
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePinching: true,
                              enablePanning: true,
                              zoomMode: ZoomMode.xy,
                            ),
                            tooltipBehavior: TooltipBehavior(
                              enable: true,
                              format: 'Energy: point.y W\nTime: point.x',
                            ),
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timeline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text("No history data available.",
                                    style: TextStyle(color: Colors.grey, fontSize: 18)),
                                SizedBox(height: 8),
                                Text("Click 'Load Historical Data' to fetch from logs",
                                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            )),
              ),
              const SizedBox(height: 20),
              // Responsive button layout - wrap on small screens, row on larger screens
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    // Stack buttons vertically on small screens
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 1),
                            child: _isLoadingHistorical 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text("Day View"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 7),
                            child: _isLoadingHistorical 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text("Week View"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 30),
                            child: _isLoadingHistorical 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text("Month View"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Use row layout on larger screens
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 1),
                              child: _isLoadingHistorical 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text("Day View"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 7),
                              child: _isLoadingHistorical 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text("Week View"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isLoadingHistorical ? null : () => _fetchHistoricalData(days: 30),
                              child: _isLoadingHistorical 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text("Month View"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePage() {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.all(constraints.maxWidth < 400 ? 12.0 : 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Energy Profile",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: constraints.maxWidth < 400 ? 16 : 24)),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadProfiles(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final profiles = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: ownerName.isNotEmpty
                            ? ownerName
                            : (profiles.isNotEmpty ? profiles[0]['name'] : null),
                        hint: const Text("Select Profile",
                            style: TextStyle(color: Colors.white)),
                        dropdownColor: const Color(0xFF2A3555),
                        items: profiles.map((profile) {
                          return DropdownMenuItem<String>(
                            value: profile['name'],
                            child: Text(profile['name'],
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            final selected =
                                profiles.firstWhere((p) => p['name'] == value);
                            setState(() {
                              ownerName = selected['name'];
                              _avatarImage = selected['avatarPath'] != null &&
                                      selected['avatarPath'].isNotEmpty
                                  ? File(selected['avatarPath'])
                                  : null;
                              _achievements =
                                  List<String>.from(selected['achievements'] ?? []);
                              _energyScore = selected['energyScore'] ?? 0.0;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () async {
                          final newProfile = await _showCreateProfileDialog();
                          if (newProfile != null) {
                            await _saveProfile(newProfile);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: CircleAvatar(
                    radius: constraints.maxWidth < 400 ? 40 : 60,
                    backgroundImage:
                        _avatarImage != null ? FileImage(_avatarImage!) : null,
                    child: _avatarImage == null
                        ? Icon(Icons.person, size: constraints.maxWidth < 400 ? 40 : 60, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth < 400 ? 10 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: $ownerName",
                          style: TextStyle(
                              fontSize: constraints.maxWidth < 400 ? 16 : 22, color: const Color.fromARGB(255, 6, 6, 6))),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Energy Score",
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF4CAF50))),
                          Text("${(_energyScore * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _energyScore,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 20),
                      Text("Achievements",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontSize: constraints.maxWidth < 400 ? 16 : 20)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildAchievementChip("Eco Warrior", Colors.green[700]!,
                              _achievements.contains("Eco Warrior")),
                          _buildAchievementChip("Peak Saver", Colors.blue[700]!,
                              _achievements.contains("Peak Saver")),
                          _buildAchievementChip("Solar Star", Colors.yellow[700]!,
                              _achievements.contains("Solar Star")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnergyChallengeScreen(
                        onAchievementsEarned: (earned, score) async {
                          setState(() {
                            for (final a in earned) {
                              if (!_achievements.contains(a)) _achievements.add(a);
                            }
                            _energyScore = score;
                          });
                          await _updateCurrentProfile();
                        },
                      ),
                    ),
                  );
                },
                child: const Text("Take Energy Challenge"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _achievements = [];
  double _energyScore = 0.92;

  Future<List<Map<String, dynamic>>> _loadProfiles() async {
    final file = File('${(await getDatabasesPath())}/profiles.json');
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode([
        {
          "name": "John Doe",
          "avatarPath": "",
          "achievements": ["Eco Warrior"],
          "energyScore": 0.85
        },
        {
          "name": "Jane Smith",
          "avatarPath": "",
          "achievements": ["Peak Saver", "Solar Star"],
          "energyScore": 0.92
        }
      ]));
    }
    final content = await file.readAsString();
    return List<Map<String, dynamic>>.from(jsonDecode(content));
  }

  Future<void> _saveProfile(Map<String, dynamic> profile) async {
    final file = File('${(await getDatabasesPath())}/profiles.json');
    List<Map<String, dynamic>> profiles = [];
    if (await file.exists()) {
      profiles =
          List<Map<String, dynamic>>.from(jsonDecode(await file.readAsString()));
    }
    profiles.add(profile);
    await file.writeAsString(jsonEncode(profiles));
  }

  Future<void> _updateCurrentProfile() async {
    final file = File('${(await getDatabasesPath())}/profiles.json');
    if (!await file.exists()) return;
    final profiles =
        List<Map<String, dynamic>>.from(jsonDecode(await file.readAsString()));
    final idx = profiles.indexWhere((p) => p['name'] == ownerName);
    if (idx != -1) {
      profiles[idx]['achievements'] = _achievements;
      profiles[idx]['energyScore'] = _energyScore;
      profiles[idx]['avatarPath'] = _avatarImage?.path ?? "";
      await file.writeAsString(jsonEncode(profiles));
    }
  }

  Future<Map<String, dynamic>?> _showCreateProfileDialog() async {
    String newName = "";
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Profile"),
          content: TextField(
            decoration: const InputDecoration(hintText: "Enter name"),
            onChanged: (val) => newName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (newName.trim().isEmpty) return;
                Navigator.pop(context, {
                  "name": newName.trim(),
                  "avatarPath": "",
                  "achievements": [],
                  "energyScore": 0.0,
                });
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementChip(String label, Color color, bool achieved) {
    return Chip(
      label: Text(label,
          style:
              TextStyle(color: achieved ? Colors.white : Colors.white54)),
      backgroundColor: achieved ? color : color.withAlpha(77),
      avatar: achieved
          ? const Icon(Icons.check_circle, color: Colors.white, size: 20)
          : const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    database?.close();
    super.dispose();
  }
}

// AI API for Energy Insights
class AIEnergyInsights {
  // Helper function to safely convert watts to double
  static double _safeWattsToDouble(dynamic watts) {
    if (watts is int) return watts.toDouble();
    if (watts is double) return watts;
    if (watts is String) return double.tryParse(watts) ?? 0.0;
    return 0.0;
  }

  static Future<String> getEnergyInsight(List<Map<String, dynamic>> historicalData, double currentWatts) async {
    try {
      // Calculate some basic metrics for AI analysis
      if (historicalData.isEmpty) {
        return "Start monitoring your energy usage to receive personalized insights!";
      }

      // Calculate average usage
      double avgUsage = historicalData.fold<double>(0.0, (double sum, item) {
        final watts = item['watts'];
        return sum + _safeWattsToDouble(watts);
      }) / historicalData.length;

      // Calculate peak usage
      double peakUsage = historicalData.fold<double>(0.0, (double max, item) {
        final watts = item['watts'];
        double wattsValue = _safeWattsToDouble(watts);
        return wattsValue > max ? wattsValue : max;
      });

      // Calculate usage trend (comparing recent vs older data)
      int midPoint = historicalData.length ~/ 2;
      double recentAvg = 0.0;
      double olderAvg = 0.0;
      
      if (historicalData.length > 1) {
        List<Map<String, dynamic>> recentData = historicalData.take(midPoint).toList();
        List<Map<String, dynamic>> olderData = historicalData.skip(midPoint).toList();
        
        recentAvg = recentData.fold<double>(0.0, (double sum, item) {
          final watts = item['watts'];
          return sum + _safeWattsToDouble(watts);
        }) / recentData.length;
        
        olderAvg = olderData.fold<double>(0.0, (double sum, item) {
          final watts = item['watts'];
          return sum + _safeWattsToDouble(watts);
        }) / olderData.length;
      }

      // Generate AI insights based on data analysis
      List<String> insights = [];
      
      // Current usage analysis
      if (currentWatts > avgUsage * 1.5) {
        insights.add("Your current usage is ${currentWatts.toStringAsFixed(1)}W, which is 50% above average. Consider reducing appliance usage.");
      } else if (currentWatts < avgUsage * 0.5) {
        insights.add("Great job! Your current usage is well below average. Keep up the energy efficiency!");
      }

      // Peak usage analysis
      if (peakUsage > 100) {
        insights.add("Peak usage reached ${peakUsage.toStringAsFixed(1)}W. Try to spread out heavy appliance usage.");
      }

      // Trend analysis
      if (recentAvg > olderAvg * 1.2) {
        insights.add("Usage trend is increasing. Consider implementing energy-saving habits.");
      } else if (recentAvg < olderAvg * 0.8) {
        insights.add("Excellent! Your energy usage is trending downward. Your efficiency efforts are working!");
      }

      // Time-based recommendations
      int hour = DateTime.now().hour;
      if (hour >= 6 && hour <= 9) {
        insights.add("Morning peak hours (6-9 AM): Consider delaying non-essential appliance use until off-peak hours.");
      } else if (hour >= 17 && hour <= 21) {
        insights.add("Evening peak hours (5-9 PM): This is typically the highest energy demand period. Use appliances earlier or later if possible.");
      }

      // General recommendations
      if (avgUsage > 80) {
        insights.add("Your average usage is high. Consider upgrading to energy-efficient appliances or LED lighting.");
      }

      // If no specific insights, provide general advice
      if (insights.isEmpty) {
        insights.add("Your energy usage looks good! Continue monitoring and look for opportunities to optimize further.");
      }

      // Return the most relevant insight (first one)
      return insights.first;
      
    } catch (e) {
      print('AI Insight Error: $e');
      return "Monitor your energy patterns to receive personalized insights!";
    }
  }
}