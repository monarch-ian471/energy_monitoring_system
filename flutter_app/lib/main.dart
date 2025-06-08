import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rive/rive.dart' hide LinearGradient;

void main() {
  runApp(const EnergyMonitorApp());
}

class EnergyMonitorApp extends StatelessWidget {
  const EnergyMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Energy Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A1F33),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE0E7FF), fontSize: 16),
          headlineSmall: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        cardColor: const Color(0xFF1E2A44),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1F33),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFE0E7FF)),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}

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
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildOnboardingPage("Welcome to the Future!", "Monitor energy in real-time.", Colors.green),
              _buildOnboardingPage("Master Your Usage", "Control every appliance.", Colors.blue),
              _buildOnboardingPage("See the Past, Shape the Future", "Explore trends with style.", Colors.teal),
              _buildOnboardingPage("Your Energy, Your Rules", "Offline-ready and smart.", Colors.cyan, isLast: true),
            ],
          ),
          Positioned(
            bottom: 20,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) => ownerName = value,
                          style: const TextStyle(color: Color(0xFFE0E7FF)),
                          decoration: InputDecoration(
                            hintText: "Enter your name",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: const Color(0xFF2A3555),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnergyDashboard(initialName: ownerName),
                              ),
                            );
                          },
                          child: const Text("Launch Energy Control"),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
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
  }

  Widget _buildOnboardingPage(String title, String description, Color color, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), const Color(0xFF0A1F33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.energy_savings_leaf, size: 100, color: Colors.white),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF4CAF50) : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class EnergyDashboard extends StatefulWidget {
  final String initialName;
  const EnergyDashboard({Key? key, required this.initialName}) : super(key: key);

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends State<EnergyDashboard> {
  String currentWatts = "0";
  List<Map<String, dynamic>> history = [];
  String ownerName = "";
  Database? database;
  bool advancedMode = false;
  bool _isFetching = false;
  int _currentIndex = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool powerBoost = false;

  @override
  void initState() {
    super.initState();
    ownerName = widget.initialName;
    _initDatabase();
    _fetchData();
    _initSpeech();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'energy_data.db');
    database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute("CREATE TABLE cache(id INTEGER PRIMARY KEY, timestamp TEXT, watts REAL)");
      },
      version: 1,
    );
  }

  void _initSpeech() async {
    await _speech.initialize();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak("Welcome to your energy control center, $ownerName.");
  }

  static Future<Map<String, dynamic>> _fetchDataIsolate(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch data');
  }

  Future<void> _fetchData() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    try {
      final results = await Future.wait([
        compute(_fetchDataIsolate, 'http://172.20.10.2:8000/energy'),
        compute(_fetchDataIsolate, 'http://172.20.10.2:8000/energy/history'),
      ]);

      final latest = results[0];
      final historyData = results[1];

      if (latest.containsKey('error')) throw Exception('No data available from /energy');
      if (historyData.containsKey('error')) throw Exception('No history data available');

      setState(() {
        currentWatts = latest['watts'].toStringAsFixed(2);
        history = List<Map<String, dynamic>>.from(historyData as Iterable);
      });

      await database?.delete('cache');
      for (var item in history) {
        await database?.insert('cache', {'timestamp': item['timestamp'], 'watts': item['watts']});
      }
    } catch (e) {
      final cachedData = await database?.query('cache', orderBy: 'timestamp DESC', limit: 24);
      if (cachedData != null && mounted) {
        setState(() {
          history = cachedData.map((e) => {'timestamp': e['timestamp'] as String, 'watts': e['watts'] as double}).toList();
          currentWatts = history.isNotEmpty ? history.first['watts'].toStringAsFixed(2) : "Offline";
        });
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _generatePdfReport() async {
    // Placeholder for PDF generation
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? "Good Morning" : hour < 17 ? "Good Afternoon" : "Good Evening";

    Widget getCurrentPage() {
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.energy_savings_leaf, color: Colors.white, size: 40),
            const SizedBox(width: 10),
            const Text("Energy Monitor", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.print_outlined), onPressed: _generatePdfReport),
          Switch(value: advancedMode, activeColor: const Color(0xFF4CAF50), onChanged: (value) => setState(() => advancedMode = value)),
        ],
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: getCurrentPage()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E2A44),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: const Color(0xFFE0E7FF),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isFetching
            ? null
            : () {
                _fetchData();
                setState(() => powerBoost = !powerBoost);
              },
        backgroundColor: powerBoost ? Colors.red : const Color(0xFF4CAF50),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildHomePage(String greeting) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: constraints.maxWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2A3555)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$greeting, $ownerName!", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Current Usage: $currentWatts W", style: const TextStyle(fontSize: 18, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("Energy Globe", style: Theme.of(context).textTheme.headlineSmall),
            Container(
              height: constraints.maxWidth > 600 ? 400 : 300,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF1E2A44)),
              child: const Center(child: Text("3D Globe Placeholder", style: TextStyle(color: Colors.white))),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("AI Insight", style: TextStyle(fontSize: 18, color: Color(0xFF4CAF50))),
                    const SizedBox(height: 10),
                    Text("Reduce TV usage by 10% to save 15 kWh this month.", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Time Spiral", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: history.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: <CartesianSeries>[
                      SplineSeries<Map<String, dynamic>, String>(
                        dataSource: history,
                        xValueMapper: (data, _) => data['timestamp'],
                        yValueMapper: (data, _) => data['watts'],
                        color: const Color(0xFF4CAF50),
                        animationDuration: 1000,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Energy Concierge", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            child: RiveAnimation.network('https://cdn.rive.app/animations/vehicles.riv'),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: $ownerName", style: const TextStyle(fontSize: 20, color: Color(0xFFE0E7FF))),
                  const SizedBox(height: 10),
                  Text("Energy Score: 85%", style: const TextStyle(fontSize: 18, color: Color(0xFF4CAF50))),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {}, child: const Text("Take Energy Quiz")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    database?.close();
    super.dispose();
  }
}