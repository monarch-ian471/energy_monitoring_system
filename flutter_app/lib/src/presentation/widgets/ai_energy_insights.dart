import 'package:flutter/material.dart';

class AIEnergyInsightsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> historicalData;
  final double currentWatts;

  const AIEnergyInsightsWidget(
      {super.key, required this.historicalData, required this.currentWatts});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AIEnergyInsights.getEnergyInsight(historicalData, currentWatts),
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
              Text("Analyzing your energy data..."),
            ],
          );
        }

        return Text(
          snapshot.data ?? "Unable to generate insights at this time.",
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ); // Ensured return
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

  static Future<String> getEnergyInsight(
      List<Map<String, dynamic>> historicalData, double currentWatts) async {
    try {
      // Calculate some basic metrics for AI analysis
      if (historicalData.isEmpty) {
        return "Start monitoring your energy usage to receive personalized insights!";
      }

      // Calculate average usage
      double avgUsage = historicalData.fold<double>(0.0, (double sum, item) {
            final watts = item['watts'];
            return sum + _safeWattsToDouble(watts);
          }) /
          historicalData.length;

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
        List<Map<String, dynamic>> recentData =
            historicalData.take(midPoint).toList();
        List<Map<String, dynamic>> olderData =
            historicalData.skip(midPoint).toList();

        recentAvg = recentData.fold<double>(0.0, (double sum, item) {
              final watts = item['watts'];
              return sum + _safeWattsToDouble(watts);
            }) /
            recentData.length;

        olderAvg = olderData.fold<double>(0.0, (double sum, item) {
              final watts = item['watts'];
              return sum + _safeWattsToDouble(watts);
            }) /
            olderData.length;
      }

      // Generate AI insights based on data analysis
      List<String> insights = [];

      // Current usage analysis
      if (currentWatts > avgUsage * 1.5) {
        insights.add(
            "Your current usage is ${currentWatts.toStringAsFixed(1)}W, which is 50% above average. Consider reducing appliance usage.");
      } else if (currentWatts < avgUsage * 0.5) {
        insights.add(
            "Great job! Your current usage is well below average. Keep up the energy efficiency!");
      }

      // Peak usage analysis
      if (peakUsage > 100) {
        insights.add(
            "Peak usage reached ${peakUsage.toStringAsFixed(1)}W. Try to spread out heavy appliance usage.");
      }

      // Trend analysis
      if (recentAvg > olderAvg * 1.2) {
        insights.add(
            "Usage trend is increasing. Consider implementing energy-saving habits.");
      } else if (recentAvg < olderAvg * 0.8) {
        insights.add(
            "Excellent! Your energy usage is trending downward. Your efficiency efforts are working!");
      }

      // Time-based recommendations
      int hour = DateTime.now().hour;
      if (hour >= 6 && hour <= 9) {
        insights.add(
            "Morning peak hours (6-9 AM): Consider delaying non-essential appliance use until off-peak hours.");
      } else if (hour >= 17 && hour <= 21) {
        insights.add(
            "Evening peak hours (5-9 PM): This is typically the highest energy demand period. Use appliances earlier or later if possible.");
      }

      // General recommendations
      if (avgUsage > 80) {
        insights.add(
            "Your average usage is high. Consider upgrading to energy-efficient appliances or LED lighting.");
      }

      // If no specific insights, provide general advice
      if (insights.isEmpty) {
        insights.add(
            "Your energy usage looks good! Continue monitoring and look for opportunities to optimize further.");
      }

      // Return the most relevant insight (first one)
      return insights.first;
    } catch (e) {
      print('AI Insight Error: $e');
      return "Monitor your energy patterns to receive personalized insights!";
    }
  }
}
