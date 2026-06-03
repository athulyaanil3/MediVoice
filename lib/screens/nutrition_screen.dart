import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/calorie_journal.dart';
import '../providers/water_provider.dart';
import '../services/openai_food_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() =>
      _NutritionScreenState();
}

class _NutritionScreenState
    extends State<NutritionScreen> {

  File? selectedImage;

  String detectedFood = '';

  String calories = '';

  String protein = '';

  String carbs = '';

  String fat = '';

  String healthScore = '';

  String benefits = '';
  String foodType = '';

  bool scanning = false;

  final TextEditingController foodController =
  TextEditingController();

  Future<void> analyzeManualFood() async {
    final foodName = foodController.text.trim();

    if (foodName.isEmpty) return;

    setState(() {
      scanning = true;
    });

    try {
      final response =
      await OpenAIFoodService.analyzeFoodName(
        foodName,
      );

      final data = jsonDecode(response);

      setState(() {
        detectedFood = data['name'] ?? foodName;

        foodType = data['type'] ?? 'Food';

        calories = data['calories'].toString();

        protein = '${data['protein']}g';

        carbs = '${data['carbs']}g';

        fat = '${data['fat']}g';

        healthScore = data['healthScore'] ?? 'Good';

        benefits = data['benefits'] ?? '';

        scanning = false;
      });
    } catch (e) {
      setState(() {
        scanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  void _showCalorieGoalDialog(BuildContext context) {
    final calorieJournal = context.read<CalorieJournal>();
    final manualController =
        TextEditingController(text: calorieJournal.calorieGoal.toString());

    // Calculator Controllers
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    String selectedGender = 'Male';
    String selectedActivity = 'Moderately Active';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Live preview calculation logic
            final ageVal = int.tryParse(ageController.text.trim());
            final weightVal = double.tryParse(weightController.text.trim());
            final heightVal = double.tryParse(heightController.text.trim());

            int? calculatedPreview;
            if (ageVal != null &&
                weightVal != null &&
                heightVal != null &&
                ageVal > 0 &&
                weightVal > 0 &&
                heightVal > 0) {
              double bmr;
              if (selectedGender == 'Male') {
                bmr = 10 * weightVal + 6.25 * heightVal - 5 * ageVal + 5;
              } else {
                bmr = 10 * weightVal + 6.25 * heightVal - 5 * ageVal - 161;
              }
              double factor = 1.2;
              switch (selectedActivity) {
                case 'Sedentary':
                  factor = 1.2;
                  break;
                case 'Lightly Active':
                  factor = 1.375;
                  break;
                case 'Moderately Active':
                  factor = 1.55;
                  break;
                case 'Very Active':
                  factor = 1.725;
                  break;
              }
              calculatedPreview = (bmr * factor).round();
            }

            final updateListener = () {
              setStateDialog(() {});
            };

            // Add listeners once to update preview dynamically
            ageController.removeListener(updateListener);
            ageController.addListener(updateListener);
            weightController.removeListener(updateListener);
            weightController.addListener(updateListener);
            heightController.removeListener(updateListener);
            heightController.addListener(updateListener);

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppTheme.accentCoral),
                  SizedBox(width: 10),
                  Text('Daily Calorie Goal'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Manual Goal',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: manualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 2000 kcal',
                        labelText: 'Calories (kcal)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'OR USE CALCULATOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Suggested Goal Calculator',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Age & Gender Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              hintText: 'e.g. 25',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                            ),
                            items: ['Male', 'Female']
                                .map((g) => DropdownMenuItem(
                                    value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setStateDialog(() => selectedGender = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Weight & Height Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              hintText: 'e.g. 70',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              hintText: 'e.g. 175',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Activity Level Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedActivity,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                      ),
                      items: [
                        'Sedentary',
                        'Lightly Active',
                        'Moderately Active',
                        'Very Active'
                      ]
                          .map((a) =>
                              DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedActivity = val);
                        }
                      },
                    ),

                    if (calculatedPreview != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCoral.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentCoral.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Calculated Recommendation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentCoral,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$calculatedPreview kcal / day',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentCoral,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    int finalGoal = 2000;

                    // If calculator fields are not empty, calculate suggested goal, else use manual goal
                    final ageText = ageController.text.trim();
                    final weightText = weightController.text.trim();
                    final heightText = heightController.text.trim();

                    if (ageText.isNotEmpty &&
                        weightText.isNotEmpty &&
                        heightText.isNotEmpty) {
                      final age = int.tryParse(ageText);
                      final weight = double.tryParse(weightText);
                      final height = double.tryParse(heightText);

                      if (age == null ||
                          weight == null ||
                          height == null ||
                          age <= 0 ||
                          weight <= 0 ||
                          height <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please enter valid calculator values.')),
                        );
                        return;
                      }

                      double bmr;
                      if (selectedGender == 'Male') {
                        bmr = 10 * weight + 6.25 * height - 5 * age + 5;
                      } else {
                        bmr = 10 * weight + 6.25 * height - 5 * age - 161;
                      }

                      double factor = 1.2;
                      switch (selectedActivity) {
                        case 'Sedentary':
                          factor = 1.2;
                          break;
                        case 'Lightly Active':
                          factor = 1.375;
                          break;
                        case 'Moderately Active':
                          factor = 1.55;
                          break;
                        case 'Very Active':
                          factor = 1.725;
                          break;
                      }

                      finalGoal = (bmr * factor).round();
                    } else {
                      final manualText = manualController.text.trim();
                      final parsed = int.tryParse(manualText);
                      if (parsed == null || parsed <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please enter a valid manual calorie goal.')),
                        );
                        return;
                      }
                      finalGoal = parsed;
                    }

                    await calorieJournal.setCalorieGoal(finalGoal);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Daily Calorie Goal set to $finalGoal kcal!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickLogDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    String selectedMeal = 'Breakfast';
    
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      selectedMeal = 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      selectedMeal = 'Lunch';
    } else if (hour >= 16 && hour < 21) {
      selectedMeal = 'Dinner';
    } else {
      selectedMeal = 'Snack';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: AppTheme.deepTeal),
                  SizedBox(width: 10),
                  Text('Log Meal Manually'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        hintText: 'e.g., Rice, Oatmeal, Chicken',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories (kcal)',
                        hintText: 'e.g., 250',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMeal,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                      ),
                      items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            selectedMeal = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final foodName = nameController.text.trim();
                    final calText = caloriesController.text.trim();
                    
                    if (foodName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter food name')),
                      );
                      return;
                    }
                    
                    final cals = int.tryParse(calText);
                    if (cals == null || cals < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid calories')),
                      );
                      return;
                    }

                    await context.read<CalorieJournal>().addEntry(
                      label: foodName,
                      calories: cals,
                      meal: selectedMeal,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logged $foodName ($cals kcal) as $selectedMeal!')),
                    );
                  },
                  child: const Text('Log'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    foodController.dispose();
    super.dispose();
  }

  Future<void> pickFoodImage({
    required ImageSource source,
  }) async {

    final picked =
    await ImagePicker().pickImage(
      source: source,
    );

    if (picked == null) return;

    setState(() {

      selectedImage =
          File(picked.path);

      scanning = true;
    });

    try {

      final response =
      await OpenAIFoodService.analyzeFood(
        File(picked.path),
      );

      final raw =
      response['raw'];

      final data =
      jsonDecode(raw);

      setState(() {

        detectedFood =
            data['name'] ?? 'Unknown';

        calories =
            data['calories'].toString();

        protein =
        '${data['protein']}g';

        carbs =
        '${data['carbs']}g';

        fat =
        '${data['fat']}g';

        healthScore =
            data['healthScore'] ?? 'Good';

        scanning = false;
      });

    } catch (e) {

      setState(() {

        scanning = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
          Text(
            'Error analyzing food: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final j =
    context.watch<CalorieJournal>();

    final waterProvider =
    context.watch<WaterProvider>();

    return MediBackground(

      pad: false,

      child:
      SingleChildScrollView(

        padding:
        const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          120,
        ),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            PageHeader(

              title: 'Food Log',

              subtitle:
              'Track calories, meals & hydration',
            ),

            // CALORIE CARD

            GlassCard(

              child: Column(

                children: [

                  Row(

                    children: [

                      Container(

                        padding:
                        const EdgeInsets.all(12),

                        decoration:
                        BoxDecoration(

                          gradient:
                          AppTheme.coralGradient,

                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: const Icon(

                          Icons.local_fire_department,

                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(

                        child: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text('Today'),

                            Text(

                              '${j.todayTotal} / ${j.calorieGoal} kcal',

                              style:
                              const TextStyle(

                                fontSize: 24,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${j.caloriesRemaining} left',
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _showCalorieGoalDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  LinearProgressIndicator(

                    value:
                    j.todayProgress
                        .clamp(0.0, 1.0),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(

                    width: double.infinity,

                    child:
                    FilledButton.icon(
                      onPressed: () => _showQuickLogDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Log Meal'),
                    ),
                  ),

                  if (j.todayEntries.isNotEmpty) ...[
                    const Divider(height: 28),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: j.todayEntries.length,
                      itemBuilder: (context, index) {
                        final entry = j.todayEntries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.deepTeal.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.meal ?? 'Snack',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.deepTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${entry.calories} kcal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.accentCoral,
                                  size: 22,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Log'),
                                      content: Text('Delete "${entry.label}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: AppTheme.accentCoral),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await j.deleteEntry(entry.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Removed ${entry.label}'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // HYDRATION CARD

            GlassCard(

              child: Column(

                children: [

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      const Text(

                        'Current Hydration',

                        style: TextStyle(

                          fontSize: 20,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      IconButton(

                        icon:
                        const Icon(Icons.settings),

                        onPressed: () {

                          final controller =
                          TextEditingController();

                          showDialog(

                            context: context,

                            builder: (_) {

                              return AlertDialog(

                                title:
                                const Text(
                                  'Daily Goal',
                                ),

                                content:
                                TextField(

                                  controller:
                                  controller,

                                  keyboardType:
                                  TextInputType.number,

                                  decoration:
                                  const InputDecoration(
                                    hintText:
                                    'Goal in liters',
                                  ),
                                ),

                                actions: [

                                  FilledButton(

                                    onPressed: () {

                                      final value =
                                          double.tryParse(
                                            controller.text,
                                          ) ??
                                              3.0;

                                      waterProvider
                                          .setGoal(value);

                                      Navigator.pop(
                                        context,
                                      );
                                    },

                                    child:
                                    const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  TweenAnimationBuilder<double>(

                    tween:
                    Tween(

                      begin: 0,

                      end:
                      waterProvider.progress,
                    ),

                    duration:
                    const Duration(
                      milliseconds: 1200,
                    ),

                    builder:
                        (context,
                        value,
                        child) {

                      return SizedBox(

                        height: 220,

                        width: 220,

                        child: Stack(

                          alignment:
                          Alignment.center,

                          children: [

                            SizedBox(

                              height: 220,

                              width: 220,

                              child:
                              CircularProgressIndicator(

                                value: value,

                                strokeWidth: 14,

                                backgroundColor:
                                Colors.grey.shade200,

                                valueColor:
                                const AlwaysStoppedAnimation(
                                  Color(0xFF9D7BFF),
                                ),
                              ),
                            ),

                            Column(

                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children: [

                                Text(

                                  '${(value * 100).toInt()}%',

                                  style:
                                  const TextStyle(

                                    fontSize: 42,

                                    fontWeight:
                                    FontWeight.bold,

                                    color:
                                    Color(0xFF4A2E8C),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(

                                  '${waterProvider.waterIntake.toStringAsFixed(1)} L',

                                  style:
                                  const TextStyle(

                                    fontSize: 18,

                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Row(

                    children: [

                      Expanded(

                        child:
                        _waterButton(

                          label: '180 ml',

                          color:
                          const Color(0xFFF2ECFF),

                          onTap: () {

                            waterProvider.addWater(
                              0.18,
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(

                        child:
                        _waterButton(

                          label: '250 ml',

                          color:
                          const Color(0xFFE8F5FF),

                          onTap: () {

                            waterProvider.addWater(
                              0.25,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(

                    children: [

                      Expanded(

                        child:
                        _waterButton(

                          label: '500 ml',

                          color:
                          const Color(0xFFFFF5E6),

                          onTap: () {

                            waterProvider.addWater(
                              0.5,
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(

                        child:
                        _waterButton(

                          label: '750 ml',

                          color:
                          const Color(0xFFFFEBF1),

                          onTap: () {

                            waterProvider.addWater(
                              0.75,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SizedBox(

                    width: double.infinity,

                    child:
                    FilledButton(

                      style:
                      FilledButton.styleFrom(
                        backgroundColor:
                        Colors.redAccent,
                      ),

                      onPressed: () {

                        waterProvider.removeWater(
                          0.25,
                        );
                      },

                      child:
                      const Text(
                        'Remove Water',
                      ),
                    ),
                  ),

                  if (waterProvider.completed)

                    const Padding(

                      padding:
                      EdgeInsets.only(top: 20),

                      child: Column(

                        children: [

                          Icon(

                            Icons.emoji_events,

                            color: Colors.amber,

                            size: 55,
                          ),

                          SizedBox(height: 10),

                          Text(

                            'Hydration Goal Completed 🎉',

                            style: TextStyle(

                              color: Colors.green,

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FOOD SCANNER

            const Text(

              'AI Food Scanner',

              style: TextStyle(

                fontSize: 20,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Row(

              children: [

                Expanded(

                  child:
                  FilledButton.icon(

                    onPressed: () {

                      pickFoodImage(
                        source:
                        ImageSource.camera,
                      );
                    },

                    icon:
                    const Icon(
                      Icons.camera_alt,
                    ),

                    label:
                    const Text('Camera'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child:
                  FilledButton.icon(

                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      Colors.green,
                    ),

                    onPressed: () {

                      pickFoodImage(
                        source:
                        ImageSource.gallery,
                      );
                    },

                    icon:
                    const Icon(
                      Icons.photo_library,
                    ),

                    label:
                    const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: foodController,
              decoration: InputDecoration(
                hintText: 'Enter food name manually',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                prefixIcon: const Icon(
                  Icons.restaurant_menu_rounded,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: analyzeManualFood,
                ),
              ),
              onSubmitted: (_) => analyzeManualFood(),
            ),

            const SizedBox(height: 20),

            if (scanning)

              const Center(
                child:
                CircularProgressIndicator(),
              ),

            if ((selectedImage != null ||
                detectedFood.isNotEmpty) &&
                !scanning)

              GlassCard(

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: selectedImage != null
                            ? Image.file(
                          selectedImage!,
                          height: 180,
                          width: 180,
                          fit: BoxFit.cover,
                        )
                            : const Icon(
                          Icons.restaurant,
                          size: 120,
                          color: Colors.orange,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        detectedFood,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(foodType),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'AI detected your meal successfully',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(

                      mainAxisAlignment:
                      MainAxisAlignment.spaceAround,

                      children: [

                        _nutritionStat(

                          icon:
                          Icons.local_fire_department,

                          value:
                          calories,

                          label:
                          'kcal',
                        ),

                        _nutritionStat(

                          icon:
                          Icons.water_drop,

                          value:
                          carbs,

                          label:
                          'carbs',
                        ),

                        _nutritionStat(

                          icon:
                          Icons.fitness_center,

                          value:
                          protein,

                          label:
                          'protein',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(

                      padding:
                      const EdgeInsets.all(18),

                      decoration:
                      BoxDecoration(

                        color:
                        Colors.green.shade50,

                        borderRadius:
                        BorderRadius.circular(18),
                      ),

                      child: Row(

                        children: [

                          const Icon(

                            Icons.favorite,

                            color: Colors.green,
                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                const Text(
                                  'Health Score',
                                ),

                                const SizedBox(height: 4),

                                Text(

                                  healthScore,

                                  style:
                                  const TextStyle(

                                    color:
                                    Colors.green,

                                    fontWeight:
                                    FontWeight.bold,

                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.tealLight,
                        ),
                        onPressed: () async {
                          final calVal = int.tryParse(
                            calories.replaceAll(RegExp(r'[^0-9]'), '')
                          ) ?? 0;
                          
                          final hour = DateTime.now().hour;
                          String meal = 'Snack';
                          if (hour >= 5 && hour < 11) {
                            meal = 'Breakfast';
                          } else if (hour >= 11 && hour < 16) {
                            meal = 'Lunch';
                          } else if (hour >= 16 && hour < 21) {
                            meal = 'Dinner';
                          }

                          await context.read<CalorieJournal>().addEntry(
                            label: detectedFood,
                            calories: calVal,
                            meal: meal,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged $detectedFood ($calVal kcal) as $meal!'),
                            ),
                          );

                          setState(() {
                            detectedFood = '';
                            calories = '';
                            protein = '';
                            carbs = '';
                            fat = '';
                            healthScore = '';
                            selectedImage = null;
                            foodController.clear();
                          });
                        },
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Log to Journal'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _waterButton({

    required String label,

    required Color color,

    required VoidCallback onTap,
  }) {

    return Material(

      color: color,

      borderRadius:
      BorderRadius.circular(18),

      child: InkWell(

        onTap: onTap,

        borderRadius:
        BorderRadius.circular(18),

        child: Padding(

          padding:
          const EdgeInsets.symmetric(
            vertical: 18,
          ),

          child: Center(

            child: Text(

              label,

              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutritionStat({

    required IconData icon,

    required String value,

    required String label,
  }) {

    return Column(

      children: [

        Icon(

          icon,

          color:
          const Color(0xFF235347),
        ),

        const SizedBox(height: 8),

        Text(

          value,

          style:
          const TextStyle(

            fontWeight:
            FontWeight.bold,

            fontSize: 18,
          ),
        ),

        Text(

          label,

          style: TextStyle(
            color:
            Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}