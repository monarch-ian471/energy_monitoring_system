import 'package:flutter/material.dart';

class EnergyChallengeScreen extends StatefulWidget {
  final Function(List<String> achievements, double score) onAchievementsEarned;
  const EnergyChallengeScreen({super.key, required this.onAchievementsEarned});

  @override
  State<EnergyChallengeScreen> createState() => _EnergyChallengeScreenState();
}

class _EnergyChallengeScreenState extends State<EnergyChallengeScreen> {
  final List<Map<String, dynamic>> _questions = [
    {
      "question":
          "What is the most energy-efficient time to use heavy appliances?",
      "options": [
        "During peak hours",
        "During off-peak hours",
        "At noon",
        "Anytime"
      ],
      "answer": 1,
    },
    {
      "question": "Which bulb uses the least energy?",
      "options": ["Incandescent", "Halogen", "LED", "CFL"],
      "answer": 2,
    },
    {
      "question": "What does a smart meter do?",
      "options": [
        "Measures water usage",
        "Measures energy usage in real time",
        "Cools your house",
        "Charges your phone"
      ],
      "answer": 1,
    },
    {
      "question": "What is a phantom load?",
      "options": [
        "Energy used by appliances when off",
        "Energy from solar panels",
        "Wind energy",
        "None of the above"
      ],
      "answer": 0,
    },
    {
      "question": "Which is a renewable energy source?",
      "options": ["Coal", "Natural Gas", "Solar", "Oil"],
      "answer": 2,
    },
    {
      "question": "What is the best way to reduce AC energy use?",
      "options": [
        "Open windows during the day",
        "Set thermostat higher",
        "Run all day",
        "Block vents"
      ],
      "answer": 1,
    },
    {
      "question": "What is net metering?",
      "options": [
        "Paying for internet",
        "Selling excess solar energy back to the grid",
        "Measuring water",
        "None of the above"
      ],
      "answer": 1,
    },
    {
      "question": "Which appliance uses the most energy at home?",
      "options": ["Refrigerator", "TV", "Microwave", "Washing Machine"],
      "answer": 0,
    },
    {
      "question": "What is the benefit of unplugging chargers?",
      "options": [
        "Saves energy",
        "Makes phone charge faster",
        "No benefit",
        "Damages charger"
      ],
      "answer": 0,
    },
    {
      "question": "What is the main cause of peak energy demand?",
      "options": [
        "People sleeping",
        "Simultaneous use of many appliances",
        "Rainy weather",
        "Solar panels"
      ],
      "answer": 1,
    },
    {
      "question": "Which of these is NOT a renewable energy source?",
      "options": ["Wind", "Hydro", "Natural Gas", "Solar"],
      "answer": 2,
    },
    {
      "question": "What does Energy Star label mean?",
      "options": [
        "High energy use",
        "Energy efficient product",
        "Expensive product",
        "Old product"
      ],
      "answer": 1,
    },
    {
      "question": "What is the best way to save energy with lighting?",
      "options": [
        "Use more lamps",
        "Use LED bulbs",
        "Leave lights on",
        "Use candles"
      ],
      "answer": 1,
    },
    {
      "question": "What is a solar inverter?",
      "options": [
        "Converts DC to AC",
        "Stores energy",
        "Cools solar panels",
        "Measures sunlight"
      ],
      "answer": 0,
    },
    {
      "question": "What is the best temperature to set your fridge?",
      "options": ["0°C", "4°C (39°F)", "10°C", "20°C"],
      "answer": 1,
    },
    {
      "question": "Which is a peak saving behavior?",
      "options": [
        "Run dishwasher at 7pm",
        "Run dishwasher at 11pm",
        "Run dishwasher at 6pm",
        "Run dishwasher at 8am"
      ],
      "answer": 1,
    },
    {
      "question": "What is the main benefit of solar panels?",
      "options": ["Lower energy bills", "More heat", "More noise", "None"],
      "answer": 0,
    },
    {
      "question": "What is a kilowatt-hour?",
      "options": [
        "A measure of power",
        "A measure of energy",
        "A measure of time",
        "A measure of voltage"
      ],
      "answer": 1,
    },
    {
      "question": "Which is a solar energy achievement?",
      "options": [
        "Using solar panels",
        "Using more gas",
        "Using more coal",
        "None"
      ],
      "answer": 0,
    },
    {
      "question": "What is the best way to reduce standby power?",
      "options": [
        "Unplug devices",
        "Use more devices",
        "Leave everything plugged in",
        "Use old appliances"
      ],
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
