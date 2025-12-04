// flutter_app/lib/src/presentation/widgets/ai_energy_insights.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIEnergyInsightsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> historicalData;
  final double currentWatts;

  const AIEnergyInsightsWidget(
      {super.key, required this.historicalData, required this.currentWatts});

  @override
  Widget build(BuildContext context) {
    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    return FutureBuilder<String>(
      future: AIEnergyInsights.getEnergyInsight(
          historicalData, currentWatts, apiKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text("AI is analyzing...", style: TextStyle(color: Colors.grey)),
            ],
          );
        }

        if (snapshot.hasError) {
          return Text("Insight unavailable.",
              style: Theme.of(context).textTheme.bodyMedium);
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text("Smart Insight",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.data ?? "No insights available.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        );
      },
    );
  }
}

class AIEnergyInsights {
  static double _safeWattsToDouble(dynamic watts) {
    if (watts is int) return watts.toDouble();
    if (watts is double) return watts;
    if (watts is String) return double.tryParse(watts) ?? 0.0;
    return 0.0;
  }

  static String _generatePromptData(
      List<Map<String, dynamic>> data, double current) {
    if (data.isEmpty) return "No historical data available.";

    var recentReadings = data.take(10).map((e) => "${e['watts']}W").join(", ");
    double avg = data.fold<double>(
            0.0, (sum, item) => sum + _safeWattsToDouble(item['watts'])) /
        data.length;

    return """
    Context Data:
    - Current Real-time Usage: ${current.toStringAsFixed(1)} Watts
    - Historical Average: ${avg.toStringAsFixed(1)} Watts
    - Recent Readings (Last 10 points): [$recentReadings]
    - Time of day: ${DateTime.now().hour}:00
    """;
  }

  static Future<String> getEnergyInsight(
      List<Map<String, dynamic>> historicalData,
      double currentWatts,
      String apiKey) async {
    // 1. Validate API Key
    if (apiKey.isEmpty) {
      print("Warning: GEMINI_API_KEY is missing in .env file.");
      return _generateLocalInsight(historicalData, currentWatts);
    }

    // 2. Try Gemini API with CORRECT model name
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp', 
        apiKey: apiKey,
      );

      final dataSummary = _generatePromptData(historicalData, currentWatts);

      final prompt = Content.text('''
      You are a smart home energy analyst. 
      Analyze the following energy usage data and provide ONE single, concise, helpful sentence advising the homeowner.
      
      $dataSummary

      Rules:
      - Be friendly but professional.
      - If usage is high, suggest a specific action based on the time of day.
      - If usage is low, compliment them.
      - Max 25 words.
      - Do not use markdown formatting like bold or italics.
      ''');

      final response = await model.generateContent([prompt]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }
    } catch (e) {
      print("Gemini API Error: $e. Falling back to local logic.");
    }

    // 3. Fallback to Local Logic
    return _generateLocalInsight(historicalData, currentWatts);
  }

  static String _generateLocalInsight(
      List<Map<String, dynamic>> historicalData, double currentWatts) {
    if (historicalData.isEmpty) return "Start monitoring to see insights.";

    double avgUsage = historicalData.fold<double>(
            0.0, (sum, item) => sum + _safeWattsToDouble(item['watts'])) /
        historicalData.length;

    if (currentWatts > avgUsage * 1.5) {
      return "Usage is 50% above average. Consider turning off unused devices.";
    } else if (currentWatts < avgUsage * 0.5) {
      return "Great job! Your usage is well below your average.";
    }

    return "Your energy usage is stable. Keep it up!";
  }
}