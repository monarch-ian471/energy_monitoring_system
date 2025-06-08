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

void main() {
  runApp(const EnergyMonitorApp());
}

class EnergyMonitorApp extends StatelessWidget {
  const EnergyMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnergySphere',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0A1F33),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE0E7FF), fontSize: 16),
          headlineSmall: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 24),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        ),
        cardColor: const Color(0xFF1E2A44),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            elevation: 8,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1F33),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFE0E7FF)),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}

// Onboarding Screen
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
              _buildOnboardingPage("Welcome to EnergySphere", "Your gateway to smart energy.", "https://assets5.lottiefiles.com/packages/lf20_jcikoh8b.json", Colors.green),
              _buildOnboardingPage("Master Your Power", "Control every watt with ease.", "https://assets8.lottiefiles.com/packages/lf20_msdmfng3.json", Colors.blue),
              _buildOnboardingPage("Track & Thrive", "See your energy story unfold.", "https://assets3.lottiefiles.com/packages/lf20_khwclk6g.json", Colors.teal),
              _buildOnboardingPage("Your Energy, Reimagined", "Offline-ready, future-proof.", "https://assets1.lottiefiles.com/packages/lf20_xlmzkuov.json", Colors.cyan, isLast: true),
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
                          style: const TextStyle(color: Color(0xFFE0E7FF)),
                          decoration: InputDecoration(
                            hintText: "Enter your name",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: const Color(0xFF2A3555),
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
                                builder: (context) => EnergyDashboard(initialName: ownerName),
                              ),
                            );
                          },
                          child: const Text("Enter the EnergySphere"),
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
  }

  Widget _buildOnboardingPage(String title, String description, String lottieUrl, Color color, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // ignore: deprecated_member_use
          colors: [color.withOpacity(0.8), const Color(0xFF0A1F33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(lottieUrl, width: 300, height: 300, fit: BoxFit.contain),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: _currentPage == index ? 14 : 10,
      height: 10,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: _currentPage == index ? const Color(0xFF4CAF50) : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// Energy Dashboard
class EnergyDashboard extends StatefulWidget {
  final String initialName;
  const EnergyDashboard({Key? key, required this.initialName}) : super(key: key);

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends State<EnergyDashboard> with SingleTickerProviderStateMixin {
  String currentWatts = "0";
  List<Map<String, dynamic>> history = [];
  String ownerName = "";
  Database? database;
  bool advancedMode = false;
  bool _isFetching = false;
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
    _fetchData();
    _initSpeech();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
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
    await _flutterTts.speak("Welcome to EnergySphere, $ownerName. Let’s optimize your energy!");
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Report Generated!")));
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() => _avatarImage = File(pickedFile.path));
    }
  }

  void _listenForCommands() async {
    if (await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (result.recognizedWords.toLowerCase().contains('current usage')) {
            _flutterTts.speak('The current usage is $currentWatts watts.');
          } else if (result.recognizedWords.toLowerCase().contains('generate report')) {
            _generatePdfReport();
            _flutterTts.speak('Report generated.');
          }
        }
      },
    )) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listening...")));
    }
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network('https://img.icons8.com/ios-filled/50/ffffff/lightning-bolt.png', width: 40, height: 40),
        ),
        title: const Text("EnergySphere"),
        actions: [
          IconButton(icon: const Icon(Icons.mic), onPressed: _listenForCommands),
          IconButton(icon: const Icon(Icons.print), onPressed: _generatePdfReport),
          Switch(value: advancedMode, activeColor: const Color(0xFF4CAF50), onChanged: (value) => setState(() => advancedMode = value)),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: getCurrentPage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E2A44),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isFetching ? null : () => _fetchData(),
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
  }

  Widget _buildHomePage(String greeting) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: constraints.maxWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2A3555)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$greeting, $ownerName!", style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Current Usage", style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white70)),
                      Text("$currentWatts W", style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: SfRadialGauge(
                        axes: [
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
                            ranges: [
                              GaugeRange(startValue: 0, endValue: 33, color: Colors.green),
                              GaugeRange(startValue: 33, endValue: 66, color: Colors.orange),
                              GaugeRange(startValue: 66, endValue: 100, color: Colors.red),
                            ],
                            pointers: [NeedlePointer(value: double.tryParse(currentWatts) ?? 0, enableAnimation: true)],
                            annotations: [
                              GaugeAnnotation(
                                widget: Text('$currentWatts W', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text("Energy Globe", style: Theme.of(context).textTheme.headlineSmall),
            Container(
              height: constraints.maxWidth > 600 ? 400 : 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const RadialGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF0A1F33)],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
              child: Lottie.network('https://assets2.lottiefiles.com/packages/lf20_0xql38ob.json', fit: BoxFit.contain),
            ),
            const SizedBox(height: 30),
            ExpansionTile(
              title: Text("AI Energy Insights", style: Theme.of(context).textTheme.headlineSmall),
              collapsedBackgroundColor: const Color(0xFF1E2A44),
              backgroundColor: const Color(0xFF2A3555),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Reduce appliance usage during peak hours (6-9 PM) to save up to 20% this month!",
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (advancedMode)
              ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AR Mode Coming Soon!"))),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Launch AR View"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Energy Timeline", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: history.isEmpty
                ? Center(child: Lottie.network('https://assets6.lottiefiles.com/packages/lf20_8qetzdep.json', width: 200))
                : SfCartesianChart(
                    primaryXAxis: DateTimeAxis(),
                    series: [
                      SplineSeries<Map<String, dynamic>, DateTime>(
                        dataSource: history,
                        xValueMapper: (data, _) => DateTime.parse(data['timestamp']),
                        yValueMapper: (data, _) => data['watts'],
                        color: const Color(0xFF4CAF50),
                        animationDuration: 1000,
                        enableTooltip: true,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                    ],
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enablePanning: true,
                      zoomMode: ZoomMode.xy,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text("Day View"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Week View"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Energy Profile", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarImage != null ? FileImage(_avatarImage!) : null,
                  child: _avatarImage == null
                      ? Lottie.network('https://assets10.lottiefiles.com/packages/lf20_khwclk6g.json', width: 120, height: 120)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: $ownerName", style: const TextStyle(fontSize: 22, color: Color(0xFFE0E7FF))),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Energy Score", style: TextStyle(fontSize: 18, color: Color(0xFF4CAF50))),
                        Text("92%", style: const TextStyle(fontSize: 18, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0.92,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 20),
                    Text("Achievements", style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        Chip(label: const Text("Eco Warrior"), backgroundColor: Colors.green[700]),
                        Chip(label: const Text("Peak Saver"), backgroundColor: Colors.blue[700]),
                        Chip(label: const Text("Solar Star"), backgroundColor: Colors.yellow[700]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Take Energy Challenge"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    database?.close();
    super.dispose();
  }
}