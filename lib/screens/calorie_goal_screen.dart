import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calorie_journal.dart';

class CalorieGoalScreen extends StatefulWidget {
  const CalorieGoalScreen({super.key});

  @override
  State<CalorieGoalScreen> createState() => _CalorieGoalScreenState();
}

class _CalorieGoalScreenState extends State<CalorieGoalScreen> {

  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  String gender = 'Male';
  String activity = 'Moderately Active';

  double? calculatedGoal;

  double calculateCalories() {
    int age = int.tryParse(ageController.text.trim()) ?? 0;
    double weight = double.tryParse(weightController.text.trim()) ?? 0.0;
    double height = double.tryParse(heightController.text.trim()) ?? 0.0;

    double bmr;

    if (gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    double multiplier;

    switch (activity) {
      case 'Sedentary':
        multiplier = 1.2;
        break;
      case 'Lightly Active':
        multiplier = 1.375;
        break;
      case 'Moderately Active':
        multiplier = 1.55;
        break;
      case 'Very Active':
        multiplier = 1.725;
        break;
      default:
        multiplier = 1.9;
    }

    return bmr * multiplier;
  }

  Future<void> saveGoal() async {
    if (calculatedGoal == null) return;

    await context.read<CalorieJournal>().setCalorieGoal(calculatedGoal!.round());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily Goal Saved'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Goal Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: gender,
              items: const [
                DropdownMenuItem(
                  value: 'Male',
                  child: Text('Male'),
                ),
                DropdownMenuItem(
                  value: 'Female',
                  child: Text('Female'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  gender = v!;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: activity,
              items: const [
                DropdownMenuItem(
                  value: 'Sedentary',
                  child: Text('Little or No Exercise'),
                ),

                DropdownMenuItem(
                  value: 'Lightly Active',
                  child: Text('Exercise 1-3 Days/Week'),
                ),

                DropdownMenuItem(
                  value: 'Moderately Active',
                  child: Text('Exercise 3-5 Days/Week'),
                ),

                DropdownMenuItem(
                  value: 'Very Active',
                  child: Text('Exercise 6-7 Days/Week'),
                ),

                DropdownMenuItem(
                  value: 'Extra Active',
                  child: Text('Athlete / Physical Job'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  activity = v!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (ageController.text.isEmpty ||
                    weightController.text.isEmpty ||
                    heightController.text.isEmpty) {
                  return;
                }

                setState(() {
                  calculatedGoal = calculateCalories();
                });
              },
              child: const Text(
                'Calculate Goal',
              ),
            ),

            const SizedBox(height: 20),

            if (calculatedGoal != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${calculatedGoal!.round()} kcal/day',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: saveGoal,
                        child: const Text(
                          'Use This Goal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}