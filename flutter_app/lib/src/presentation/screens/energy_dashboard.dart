import 'package:energy_monitor_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For theme
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants.dart';
import '../../presentation/widgets/ai_energy_insights.dart';
import '../../presentation/providers/energy_provider.dart';
import '../screens/energy_challenge_screen.dart';
// import '../../domain/entities/energy_data.dart';
import '../../services/notification_service.dart';

class EnergyDashboard extends ConsumerStatefulWidget {
  final String initialName;
  const EnergyDashboard({super.key, required this.initialName});

  @override
  ConsumerState<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends ConsumerState<EnergyDashboard>
    with SingleTickerProviderStateMixin {
  String currentWatts = "0"; // Initial default
  List<Map<String, dynamic>> history = []; // Initial default
  List<Map<String, dynamic>> historicalData = [];
  List<Map<String, dynamic>> dailyStats = [];
  List<Map<String, dynamic>> appliances = [];
  String selectedApplianceName = "Main Appliance";
  String ownerName = "";
  Database? database;
  bool advancedMode = false;
  bool _isFetching = true;
  bool _isLoadingHistorical = false;
  int _currentIndex = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animationController;
  File? _avatarImage;
  List<String> _achievements = [];
  double _energyScore = 0.92;

  @override
  void initState() {
    super.initState();
    ownerName = widget.initialName;
    _initDatabase();

    _fetchAppliances().then((_) {
      _fetchData().then((_) {
        if (mounted) setState(() => _isFetching = false);
      }).catchError((e) {
        print('Fetch Error: $e');
        if (mounted) setState(() => _isFetching = false);
      });
    });

    _initSpeech();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);

    // Also load historical data from logs
    _fetchHistoricalData(days: 7).catchError((e) {
      print('Historical data init error: $e');
    });
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
      final response = await http
          .get(Uri.parse('$apiBaseUrl/logs/historical-data?days=$days'))
          .timeout(const Duration(seconds: 10), onTimeout: () {
        // Added: 10s timeout
        throw Exception('API timeout - Check if server is running');
      });
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
                'watts': item['watts'] is int
                    ? (item['watts'] as int).toDouble()
                    : item['watts'] as double,
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
            await database?.insert('cache',
                {'timestamp': item['timestamp'], 'watts': item['watts']});
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Loaded ${history.length} historical readings from logs")));
        } else if (data.containsKey('error')) {
          // Handle error response from mock server
          print('API Error: ${data['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("API Error: ${data['error']}")));
        } else {
          // Handle unexpected response format
          print('API Error: Invalid response format');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Invalid response format from server")));
        }
      } else {
        throw Exception('Failed to fetch: ${response.statusCode}');
      }
    } catch (e) {
      print('Historical data fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Error: $e - Using offline data"))); // Added: User notification
      // Fallback: Load from local DB (outside box - resilient for Malawi's networks)
      final cached = await database?.query('cache');
      if (cached != null)
        history = cached
            .map(
                (row) => {'timestamp': row['timestamp'], 'watts': row['watts']})
            .toList();
    } finally {
      if (mounted) setState(() => _isLoadingHistorical = false);
    }
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isFetching = true);
    final selectedApplianceId = ref.read(selectedApplianceProvider);
    try {
      // UPDATE THESE URLS TO INCLUDE APPLIANCE ID:
      final currentResponse = await http
          .get(Uri.parse('$apiBaseUrl/energy?applianceId=$selectedApplianceId'))
          .timeout(const Duration(seconds: 10));

      final historyResponse = await http
          .get(Uri.parse(
              '$apiBaseUrl/energy/history?applianceId=$selectedApplianceId'))
          .timeout(const Duration(seconds: 10));

      print('API Response /energy: ${currentResponse.body}');
      print('API Response /history: ${historyResponse.body}');

      if (currentResponse.statusCode == 200 &&
          historyResponse.statusCode == 200) {
        final latest = jsonDecode(currentResponse.body);
        final historyData = jsonDecode(historyResponse.body);

        // Check if data is available
        if (latest.containsKey('error')) {
          print('API Error: ${latest['error']}');
          // Fallback to cached data
          final cached = await database?.query('cache',
              orderBy: 'timestamp DESC', limit: 1);
          if (cached != null && cached.isNotEmpty) {
            setState(() {
              currentWatts = (cached.first['watts'] as num).toStringAsFixed(2);
            });
          }
          return;
        }

        final double watts = (latest['watts'] as num).toDouble();
        final double threshold = 80.0; // 80W threshold for notification

        if (watts > threshold) {
          await NotificationService().showPeakUsageAlert(
            watts,
            appliance: selectedApplianceName,
          );
        }

        setState(() {
          currentWatts = (latest['watts'] as num).toStringAsFixed(2);

          if (historyData.containsKey('data')) {
            history = List<Map<String, dynamic>>.from(historyData['data'])
                .map<Map<String, dynamic>>((item) {
              return {
                'timestamp': item['timestamp'],
                'watts': item['watts'] is int
                    ? (item['watts'] as int).toDouble()
                    : item['watts'] as double,
              };
            }).toList();
          }
        });

        // Cache the data
        await database?.delete('cache');
        for (var item in history) {
          await database?.insert('cache',
              {'timestamp': item['timestamp'], 'watts': item['watts']});
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(" Data refreshed for $selectedApplianceName")));
      } else {
        throw Exception('Failed to fetch: ${currentResponse.statusCode}');
      }
    } catch (e) {
      print('Fetch error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Using offline data")));

      // Fallback: Load from cache
      final cached = await database?.query('cache');
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          history = cached
              .map((row) =>
                  {'timestamp': row['timestamp'], 'watts': row['watts']})
              .toList();
          currentWatts = history.isNotEmpty
              ? history.first['watts'].toStringAsFixed(2)
              : "0.00";
        });
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _downloadLogFile(String logType) async {
    try {
      // For web platform, create a download link
      if (kIsWeb) {
        final response =
            await http.get(Uri.parse('$apiBaseUrl/logs/download/$logType'));
        if (response.statusCode == 200) {
          // For web, we'll use a simple approach - show a message with the data
          // In a real implementation, you'd use dart:html for proper file download
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Log data received (${response.bodyBytes.length} bytes). Web download feature coming soon!"),
            duration: const Duration(seconds: 3),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to download log file")));
        }
        return;
      }

      // For mobile platforms, use storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Storage permission required to download logs")));
          return;
        }
      }

      final response =
          await http.get(Uri.parse('$apiBaseUrl/logs/download/$logType'));
      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Could not access storage directory")));
          return;
        }

        final file = File('${directory.path}/$logType.log');
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Log file downloaded to: ${file.path}")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to download log file")));
      }
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download error: $e")));
    }
  }

  Future<void> _fetchAppliances() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/appliances'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            appliances = List<Map<String, dynamic>>.from(data['appliances']);
            // Only update selected if we have appliances and it's still default
            if (appliances.isNotEmpty) {
              final currentSelected = ref.read(selectedApplianceProvider);
              if (currentSelected == 1 && appliances.isNotEmpty) {
                ref.read(selectedApplianceProvider.notifier).state =
                    appliances[0]['id'];
                selectedApplianceName = appliances[0]['name'];
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching appliances: $e');
      // Fallback: assume single appliance
      setState(() {
        appliances = [
          {'id': 1, 'name': 'Main Appliance'}
        ];
      });
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
            title: Text(AppLocalizations.of(context)!.appTitle),
            actions: [
              //Language Switcher
              PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                tooltip: 'Change Language / Sinthani Chilankulo',
                onSelected: (Locale locale) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        locale.languageCode == 'en'
                            ? 'Language change to English'
                            : 'Chilankhulo chasintha ku Chichewa',
                      ),
                    ),
                  );
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: Locale('en', ''),
                    child: Row(
                      children: [
                        Text('🇲🇼', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text('English'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: Locale('ny', ''),
                    child: Row(
                      children: [
                        Text('🇲🇼', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text('Chichewa'),
                      ],
                    ),
                  ),
                ],
              ),

              IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _showLogDownloadDialog),
              // Theme Toggle Button
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color:
                      themeProvider.isDarkMode ? Colors.yellow : Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              ),
              Switch(
                  value: advancedMode,
                  // ignore: deprecated_member_use
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
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.bolt),
                  label: AppLocalizations.of(context)!.dashboard),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.timeline),
                  label: AppLocalizations.of(context)!.history),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: AppLocalizations.of(context)!.profile),
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

  Widget getCurrentPage() {
    if (_isFetching) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
    }
    switch (_currentIndex) {
      case 0:
        // Use local state (currentWatts & history) instead of Riverpod if the package isn't available
        final greeting = DateTime.now().hour < 12
            ? "Good Morning"
            : (DateTime.now().hour < 17 ? "Good Afternoon" : "Good Evening");
        return _buildHomePage(greeting);
      case 1:
        return _buildHistoryPage();
      case 2:
        return _buildProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomePage(String greeting) {
    final selectedApplianceId = ref.watch(selectedApplianceProvider);
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
                              : Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$greeting, $ownerName!",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                  fontSize:
                                      constraints.maxWidth < 400 ? 20 : 32)),
                      const SizedBox(height: 10),
                      DropdownButton<int>(
                        value: selectedApplianceId,
                        items: appliances
                            .map((appliance) => DropdownMenuItem<int>(
                                  value: appliance['id'],
                                  child: Text(
                                    appliance['name'],
                                    style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (int? id) {
                          if (id != null) {
                            // Update Riverpod state
                            ref.read(selectedApplianceProvider.notifier).state =
                                id;
                            // Update local state
                            setState(() {
                              selectedApplianceName = appliances
                                  .firstWhere((a) => a['id'] == id)['name'];
                              _isFetching = true;
                            });
                            // Refresh data
                            _fetchData().then((_) {
                              if (mounted) setState(() => _isFetching = false);
                            });
                          }
                        },
                        underline: Container(
                          height: 2,
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.grey[700],
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: constraints.maxWidth < 400 ? 14 : 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.currentUsage,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                      fontSize:
                                          constraints.maxWidth < 400 ? 14 : 20,
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[700])),
                          Text("$currentWatts W",
                              style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth < 400 ? 18 : 28,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF2C3E50),
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
                                            fontSize: constraints.maxWidth < 400
                                                ? 14
                                                : 20,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF2C3E50),
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
                Text(AppLocalizations.of(context)!.energyImpactScorecard,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontSize: constraints.maxWidth < 400 ? 16 : 24)),
                Container(
                  height: constraints.maxWidth > 600
                      ? 200
                      : (constraints.maxWidth < 400 ? 100 : 140),
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
                                    const Text("Average Usage",
                                        style: TextStyle(color: Colors.white)),
                                    Text(
                                        "${_calculateAverageUsage().toStringAsFixed(1)} W",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
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
                                    const Text("Peak Usage",
                                        style: TextStyle(color: Colors.white)),
                                    Text(
                                        "${_calculatePeakUsage().toStringAsFixed(1)} W",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
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
                                    const Text("Total Readings",
                                        style: TextStyle(color: Colors.white)),
                                    Text("${_getTotalReadings()}",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(
                              fontSize: constraints.maxWidth < 400 ? 16 : 24)),
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
                            historicalData.isNotEmpty
                                ? historicalData
                                : history,
                            double.tryParse(currentWatts) ?? 0.0),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                SizedBox(width: 10),
                                Text("Analyzing your energy data..."),
                              ],
                            );
                          }

                          return Text(
                            snapshot.data ??
                                "Unable to generate insights at this time.",
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
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryPage() {
    // Use historical data from logs if available, otherwise fall back to basic history
    List<Map<String, dynamic>> chartData =
        historicalData.isNotEmpty ? historicalData : history;

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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontSize: isSmallScreen ? 16 : 24)),
                  ElevatedButton.icon(
                    onPressed: _isLoadingHistorical
                        ? null
                        : () => _fetchHistoricalData(days: 7),
                    icon: _isLoadingHistorical
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.history),
                    label: _isLoadingHistorical
                        ? const Text("Loading...")
                        : const Text("Load Data"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (historicalData.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Showing log data (${sortedData.length} readings)",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (dailyStats.isNotEmpty) ...[
                Text("Daily Statistics (Last 7 Days)",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontSize: isSmallScreen ? 16 : 24)),
                const SizedBox(height: 10),
                if (isSmallScreen)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dailyStats
                        .map((stat) => SizedBox(
                              width: 120,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        stat['date'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
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
                            ))
                        .toList(),
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
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
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
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
                                    return DateTime
                                        .now(); // Fallback to current time if parsing fails
                                  }
                                },
                                yValueMapper: (data, _) {
                                  final watts = data['watts'];
                                  if (watts is int) return watts.toDouble();
                                  if (watts is double) return watts;
                                  if (watts is String)
                                    return double.tryParse(watts) ?? 0.0;
                                  return 0.0; // Default to 0 if no valid watts
                                },
                                color: const Color(0xFF4CAF50),
                                animationDuration: 1000,
                                enableTooltip: true,
                                markerSettings:
                                    const MarkerSettings(isVisible: true),
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
                                  if (watts is String)
                                    return double.tryParse(watts) ?? 0.0;
                                  return 0.0;
                                },
                                color: Colors.orange,
                                width: 3,
                                dashArray: <double>[6, 3],
                                markerSettings:
                                    const MarkerSettings(isVisible: false),
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
                              Icon(Icons.timeline,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No history data available.",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18)),
                              SizedBox(height: 8),
                              Text(
                                  "Click 'Load Historical Data' to fetch from logs",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14)),
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
                            onPressed: _isLoadingHistorical
                                ? null
                                : () => _fetchHistoricalData(days: 1),
                            child: _isLoadingHistorical
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text("Day View"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingHistorical
                                ? null
                                : () => _fetchHistoricalData(days: 7),
                            child: _isLoadingHistorical
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text("Week View"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingHistorical
                                ? null
                                : () => _fetchHistoricalData(days: 30),
                            child: _isLoadingHistorical
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text("Month View"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
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
                              onPressed: _isLoadingHistorical
                                  ? null
                                  : () => _fetchHistoricalData(days: 1),
                              child: _isLoadingHistorical
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text("Day View"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isLoadingHistorical
                                  ? null
                                  : () => _fetchHistoricalData(days: 7),
                              child: _isLoadingHistorical
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text("Week View"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isLoadingHistorical
                                  ? null
                                  : () => _fetchHistoricalData(days: 30),
                              child: _isLoadingHistorical
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text("Month View"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
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
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontSize: constraints.maxWidth < 400 ? 16 : 24)),
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
                            : (profiles.isNotEmpty
                                ? profiles[0]['name']
                                : null),
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
                              _achievements = List<String>.from(
                                  selected['achievements'] ?? []);
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
                        ? Icon(Icons.person,
                            size: constraints.maxWidth < 400 ? 40 : 60,
                            color: Colors.grey)
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
                              fontSize: constraints.maxWidth < 400 ? 16 : 22,
                              color: const Color.fromARGB(255, 6, 6, 6))),
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
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4CAF50)),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 20),
                      Text("Achievements",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                  fontSize:
                                      constraints.maxWidth < 400 ? 16 : 20)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildAchievementChip(
                              "Eco Warrior",
                              Colors.green[700]!,
                              _achievements.contains("Eco Warrior")),
                          _buildAchievementChip("Peak Saver", Colors.blue[700]!,
                              _achievements.contains("Peak Saver")),
                          _buildAchievementChip(
                              "Solar Star",
                              Colors.yellow[700]!,
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
                              if (!_achievements.contains(a))
                                _achievements.add(a);
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
      profiles = List<Map<String, dynamic>>.from(
          jsonDecode(await file.readAsString()));
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
          style: TextStyle(color: achieved ? Colors.white : Colors.white54)),
      backgroundColor: achieved ? color : color.withValues(alpha: 0.3),
      avatar: achieved
          ? const Icon(Icons.check_circle, color: Colors.white, size: 20)
          : const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
    );
  }

  // Helper methods for Energy Impact Scorecard
  double _calculateAverageUsage() {
    List<Map<String, dynamic>> dataToUse =
        historicalData.isNotEmpty ? historicalData : history;
    if (dataToUse.isEmpty) return 0.0;

    double total = dataToUse.fold<double>(0.0, (double sum, item) {
      final watts = item['watts'];
      return sum + _safeWattsToDouble(watts);
    });

    return total / dataToUse.length;
  }

  double _calculatePeakUsage() {
    List<Map<String, dynamic>> dataToUse =
        historicalData.isNotEmpty ? historicalData : history;
    if (dataToUse.isEmpty) return 0.0;

    return dataToUse.fold<double>(0.0, (double max, item) {
      final watts = item['watts'];
      double wattsValue = _safeWattsToDouble(watts);
      return wattsValue > max ? wattsValue : max;
    });
  }

  int _getTotalReadings() {
    List<Map<String, dynamic>> dataToUse =
        historicalData.isNotEmpty ? historicalData : history;
    return dataToUse.length;
  }

  // Helper function to safely convert watts to double
  double _safeWattsToDouble(dynamic watts) {
    if (watts is int) return watts.toDouble();
    if (watts is double) return watts;
    if (watts is String) return double.tryParse(watts) ?? 0.0;
    return 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    database?.close();
    super.dispose();
  }
}
