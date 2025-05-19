import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/foundation.dart';

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
        // Modified: Updated theme for futuristic look with deep blue primary color
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor:
            const Color(0xFF0A1F33), // Dark blue-gray background
        textTheme: const TextTheme(
          bodyMedium:
              TextStyle(color: Color(0xFFE0E7FF)), // Light text for contrast
          headlineSmall: TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold), // Green for headings
        ),
        cardColor: const Color(0xFF1E2A44), // Card background for depth
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // Green buttons
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1F33),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFE0E7FF)),
        ),
      ),
      home: const EnergyDashboard(),
    );
  }
}

class EnergyDashboard extends StatefulWidget {
  const EnergyDashboard({Key? key}) : super(key: key);

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
  bool _hasPrompted = false;
  // Added: Track current navigation index
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasPrompted && mounted) {
        _promptForOwnerName();
        _hasPrompted = true;
      }
    });
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'energy_data.db');
    database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE cache(id INTEGER PRIMARY KEY, timestamp TEXT, watts REAL)",
        );
      },
      version: 1,
    );
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
      // Fetch data from both endpoints concurrently using isolates for performance.
      final results = await Future.wait([
        compute(_fetchDataIsolate, 'http://192.168.1.129:8000/energy'),
        compute(_fetchDataIsolate, 'http://192.168.1.129:8000/energy/history'),
      ]);

      final latest = results[0];
      final historyData = results[1];

      if (latest.containsKey('error')) {
        throw Exception('No data available from /energy');
      }
      if (historyData.containsKey('error')) {
        throw Exception('No history data available');
      }

      setState(() {
        currentWatts = latest['watts'].toStringAsFixed(2);
        history = List<Map<String, dynamic>>.from(historyData as Iterable);
      });

      await database?.delete('cache');
      for (var item in history) {
        await database?.insert('cache', {
          'timestamp': item['timestamp'],
          'watts': item['watts'],
        });
      }
    } catch (e) {
      final cachedData =
          await database?.query('cache', orderBy: 'timestamp DESC', limit: 24);
      if (cachedData != null && mounted) {
        setState(() {
          history = cachedData
              .map((e) => {
                    'timestamp': e['timestamp'] as String,
                    'watts': e['watts'] as double,
                  })
              .toList();
          currentWatts = history.isNotEmpty
              ? history.first['watts'].toStringAsFixed(2)
              : "Offline";
        });
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _promptForOwnerName() {
    showDialog(
      context: context,
      builder: (context) {
        String tempName = ownerName;
        return AlertDialog(
          // Modified: Styled dialog for better aesthetics
          backgroundColor: const Color(0xFF1E2A44),
          title: const Text(
            "Enter Your Name",
            style: TextStyle(color: Color(0xFFE0E7FF)),
          ),
          content: TextField(
            onChanged: (value) => tempName = value,
            style: const TextStyle(color: Color(0xFFE0E7FF)),
            decoration: InputDecoration(
              hintText: "e.g., John/Jane Doe",
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF2A3555),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() => ownerName = tempName);
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                  "Energy Usage Report for ${ownerName.isNotEmpty ? ownerName : 'User'}'s Appliance"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Timestamp', 'Watts'],
                data: history
                    .map((e) => [e['timestamp'], e['watts'].toStringAsFixed(2)])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/energy_report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'energy_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    // Added: Time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }

    // Modified: Split UI into separate widgets for navigation
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
            // Modified: Updated logo asset (ensure it exists in assets/)
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10), // Added: space between logo and title
            // Modified: Change title color to white
            const Text("Energy Monitor", style: TextStyle(color: Colors.white))
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed:
                _generatePdfReport, // Unchanged: Print functionality preserved
          ),
          Switch(
            value: advancedMode,
            activeColor: const Color(0xFF4CAF50),
            onChanged: (value) => setState(() => advancedMode = value),
          ),
        ],
      ),
      body: getCurrentPage(),
      // Added: Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E2A44),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: const Color(0xFFE0E7FF),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(String greeting) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Added: Greeting banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2A3555)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$greeting, ${ownerName.isNotEmpty ? ownerName : 'User'}!",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Current Usage",
                    // Fixed: Corrected typo 'textThemejon' to 'textTheme'
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(color: const Color(0xFF4CAF50)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$currentWatts W",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 95, 95, 95),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isFetching ? null : _fetchData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              "Refresh",
              style: TextStyle(fontSize: 18),
            ),
          ),
          if (advancedMode) ...[
            const SizedBox(height: 20),
            Text(
              "Advanced Settings",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Advanced features coming soon!")),
              ),
              child: const Text(
                "Configure",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Usage History",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < history.length) {
                                final time =
                                    DateTime.parse(history[index]['timestamp']);
                                return Text(
                                  '${time.hour}:${time.minute}',
                                  style:
                                      const TextStyle(color: Color(0xFFE0E7FF)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Color(0xFFE0E7FF)),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      minX: 0,
                      maxX: history.length - 1,
                      minY: 0,
                      maxY: (history
                              .map((e) => e['watts'] as double)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(history.length, (index) {
                            return FlSpot(
                              index.toDouble(),
                              history[index]['watts'] as double,
                            );
                          }),
                          isCurved: true,
                          color: const Color(0xFF4CAF50),
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            // Fixed: Replaced deprecated 'withOpacity' with 'withValues'
                            color:
                                const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
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
          Text(
            "Profile",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Name: ${ownerName.isNotEmpty ? ownerName : 'User'}",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _promptForOwnerName,
                    child: const Text(
                      "Change Name",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
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
