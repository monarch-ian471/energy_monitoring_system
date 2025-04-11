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
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.green),
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

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _fetchData();
    // Prompt will be triggered post-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasPrompted && mounted) {
        _promptForOwnerName();
        _hasPrompted = true;
      }
    });
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'energy_cache.db');
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
      final results = await Future.wait([
        compute(_fetchDataIsolate, 'http://192.168.1.129:8000/energy'),
        compute(_fetchDataIsolate, 'http://192.168.1.129:8000/energy/history'),
      ]);

      setState(() {
        currentWatts = results[0]['watts'].toString();
        history = List<Map<String, dynamic>>.from(results[1] as Iterable);
      });

      await database?.delete('cache');
      for (var item in history) {
        await database?.insert('cache', {
          'timestamp': item['timestamp'],
          'watts': item['watts'],
        });
      }
    } catch (e) {
      final cachedData = await database?.query('cache', orderBy: 'timestamp DESC', limit: 24);
      if (cachedData != null && mounted) {
        setState(() {
          history = cachedData.map((e) => {
                'timestamp': e['timestamp'],
                'watts': e['watts'],
              }).toList();
          currentWatts = history.isNotEmpty ? history.first['watts'].toString() : "Offline";
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
        String tempName = ownerName; // Use temp variable to avoid direct state change
        return AlertDialog(
          title: const Text("Enter Your Name"),
          content: TextField(
            onChanged: (value) => tempName = value,
            decoration: const InputDecoration(hintText: "e.g., John Doe"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() => ownerName = tempName); // Update state after dialog closes
                }
              },
              child: const Text("Save"),
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
              pw.Text("Energy Usage Report for $ownerName's Appliance"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Timestamp', 'Watts'],
                data: history.map((e) => [e['timestamp'], e['watts'].toString()]).toList(),
              ),
            ],
          );
        },
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/energy_report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'energy_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            const Text("Energy Monitor"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
          ),
          Switch(
            value: advancedMode,
            onChanged: (value) => setState(() => advancedMode = value),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              ownerName.isNotEmpty ? "$ownerName's Appliance" : "Appliance",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Current Usage: $currentWatts W", style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isFetching ? null : _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              child: const Text("Refresh"),
            ),
            const SizedBox(height: 20),
            const Text("Usage History (Last 2 Hours):", style: TextStyle(fontSize: 18)),
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
                              interval: 3600000,
                              getTitlesWidget: (value, meta) {
                                final time = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                return Text('${time.hour}:${time.minute}');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: DateTime.parse(history.last['timestamp']).millisecondsSinceEpoch.toDouble(),
                        maxX: DateTime.parse(history.first['timestamp']).millisecondsSinceEpoch.toDouble(),
                        minY: 0,
                        maxY: (history.map((e) => e['watts'] as double).reduce((a, b) => a > b ? a : b) * 1.2),
                        lineBarsData: [
                          LineChartBarData(
                            spots: history
                                .map((e) => FlSpot(
                                      DateTime.parse(e['timestamp']).millisecondsSinceEpoch.toDouble(),
                                      e['watts'] as double,
                                    ))
                                .toList(),
                            isCurved: true,
                            color: Colors.green,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
            if (advancedMode) ...[
              const SizedBox(height: 20),
              const Text("Advanced Settings", style: TextStyle(fontSize: 18)),
              ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Advanced features coming soon!")),
                ),
                child: const Text("Configure"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    database?.close();
    super.dispose();
  }
}