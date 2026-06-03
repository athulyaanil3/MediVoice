import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../services/local_store.dart';
import '../models/medicine_log.dart';

class AssistantService {

  static const String groqApiKey =
      ApiKeys.groqApiKey;
  Future<String> reply(
      String userMessage,
      ) async {

    final question =
    userMessage.trim();

    if (question.isEmpty) {
      return 'Ask me about medicines, reminders, calories, food, breathing, exercise, or wellness.';
    }

    final lower =
    question.toLowerCase();

    final allowedTopics = [
      'today',
      'summary',
      'score',
      'weekly',
      'report',
      'missed',
      'coach',
      'medicine',
      'medicines',
      'tablet',
      'pill',
      'dose',
      'dosage',
      'reminder',
      'taken',
      'skipped',
      'snooze',

      'food',
      'nutrition',
      'diet',
      'calorie',
      'kcal',
      'water',
      'hydration',

      'exercise',
      'fitness',
      'workout',

      'breathing',
      'breath',
      'meditation',

      'health',
      'wellness',
    ];

    final allowed =
    allowedTopics.any(
          (t) => lower.contains(t),
    );

    if (!allowed) {
      return '''
✨ MediVoice Coach

I can help only with:

💊 Medicines
⏰ Reminders
🍎 Nutrition
🔥 Calories
💧 Water intake
🏃 Exercise
🫁 Breathing
❤️ Wellness

Please ask a health-related question.
''';
    }
    if (lower.contains('today summary')) {
      return _todaySummary();
    }

    if (lower.contains('health score')) {
      return _healthScore();
    }

    if (lower.contains('weekly report')) {
      return _weeklyReport();
    }

    if (lower.contains('water coach')) {
      return _waterCoach();
    }

    if (lower.contains('calories today')) {
      return _calorieCoach();
    }

    if (lower.contains('missed medicines') ||
        lower.contains('did i miss any medicines')) {
      return _missedMedicines();
    }
    try {
      print('Assistant Key = $groqApiKey');
      final response =
      await http.post(

        Uri.parse(
          'https://api.groq.com/openai/v1/chat/completions',
        ),

        headers: {

          'Authorization':
          'Bearer $groqApiKey',

          'Content-Type':
          'application/json',
        },

        body: jsonEncode({

          "model":
          "llama-3.3-70b-versatile",

          "messages": [

            {
              "role": "system",
              "content":
              """
You are MediVoice Coach.

Answer ONLY questions related to:

- medicines
- medicine reminders
- food logging
- calorie tracking
- water intake
- exercise
- breathing exercises
- wellness

Never answer unrelated questions.

For emergencies advise contacting local emergency services.
"""
            },

            {
              "role": "user",
              "content": question,
            }

          ],

          "temperature": 0.4,

          "max_tokens": 512,
        }),
      );

      if (response.statusCode != 200) {
        print('Groq Error: ${response.statusCode}');
        print(response.body);

        return 'Groq Error ${response.statusCode}';
      }

      final data =
      jsonDecode(
        response.body,
      );

      return data['choices'][0]
      ['message']['content'];

    } catch (e) {

      return '''
MediVoice Coach is offline.

I can help with:

• Medicines
• Reminders
• Calories
• Food
• Water intake
• Breathing
• Exercise
''';
    }
  }
  // String _todaySummary() {
  //   return 'Today Summary';
  // }
  //
  //
  // String _weeklyReport() {
  //   return 'Weekly Report';
  // }
  //
  // String _waterCoach() {
  //   return 'Water Coach';
  // }
  //
  // String _calorieCoach() {
  //   return 'Calorie Coach';
  // }
  //
  // String _missedMedicines() {
  //   return 'Missed Medicines';
  // }
  String _todaySummary() {

    final logs =
    LocalStore.readMedicineLogs();

    final now =
    DateTime.now();

    final todayLogs = logs.where(
          (e) =>
      e.time.year == now.year &&
          e.time.month == now.month &&
          e.time.day == now.day,
    );

    final taken = todayLogs.where(
          (e) => e.status == MedicineStatus.taken,
    ).length;

    final skipped = todayLogs.where(
          (e) => e.status == MedicineStatus.skipped,
    ).length;

    final snoozed = todayLogs.where(
          (e) => e.status == MedicineStatus.snoozed,
    ).length;

    final calories =
    LocalStore.todayCalorieTotal();

    final water =
    LocalStore.readWaterMlToday();

    return '''
📊 Today's Summary

💊 Taken: $taken
❌ Missed: $skipped
⏰ Snoozed: $snoozed

🍎 Calories:
$calories kcal

💧 Water:
$water ml
''';
  }
  String _healthScore() {
    final logs =
    LocalStore.readMedicineLogs();

    if (logs.isEmpty) {
      return 'No health data available yet.';
    }

    final taken = logs.where(
          (e) => e.status == MedicineStatus.taken,
    ).length;

    final adherence =
    ((taken / logs.length) * 100)
        .round();

    int score = adherence;

    final water =
    LocalStore.readWaterMlToday();

    if (water >= 2500) {
      score += 5;
    }

    final calories =
    LocalStore.todayCalorieTotal();

    if (calories >= 1200 &&
        calories <= 2500) {
      score += 5;
    }

    if (score > 100) score = 100;

    return '''
❤️ Health Score

$score / 100

💊 Adherence:
$adherence%

🍎 Calories:
$calories kcal

💧 Water:
$water ml
''';
  }
  String _missedMedicines() {

    final logs =
    LocalStore.readMedicineLogs();

    final missed = logs.where(
          (e) => e.status == MedicineStatus.skipped,
    );

    if (missed.isEmpty) {
      return '🎉 No missed medicines.';
    }

    return '''
❌ Missed Medicines

${missed.map((e) =>
    '• ${e.medicineName}').join('\n')}
''';
  }
  String _weeklyReport() {

    final logs =
    LocalStore.readMedicineLogs();

    final weekAgo =
    DateTime.now().subtract(
      const Duration(days: 7),
    );

    final weekLogs = logs.where(
          (e) => e.time.isAfter(weekAgo),
    );

    final taken = weekLogs.where(
          (e) => e.status == MedicineStatus.taken,
    ).length;

    final skipped = weekLogs.where(
          (e) => e.status == MedicineStatus.skipped,
    ).length;

    return '''
📈 Weekly Report

💊 Taken:
$taken

❌ Missed:
$skipped
''';
  }
  String _waterCoach() {

    final water =
    LocalStore.readWaterMlToday();

    final goal =
    LocalStore.readWaterGoal();

    return '''
💧 Water Coach

Goal:
$goal ml

Consumed:
$water ml

Remaining:
${goal - water} ml
''';
  }
  String _calorieCoach() {

    final calories =
    LocalStore.todayCalorieTotal();

    final goal =
    LocalStore.readCalorieGoal();

    return '''
🍎 Calorie Coach

Goal:
$goal kcal

Consumed:
$calories kcal

Remaining:
${goal - calories} kcal
''';
  }
}
