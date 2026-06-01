import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/calorie_journal.dart';
import '../providers/water_provider.dart';
import '../services/gemini_food_service.dart';
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

  bool scanning = false;

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
      await GeminiFoodService.analyzeFood(
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

                      onPressed: () {},

                      icon:
                      const Icon(Icons.add),

                      label:
                      const Text('Log Meal'),
                    ),
                  ),
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

            const SizedBox(height: 20),

            if (scanning)

              const Center(
                child:
                CircularProgressIndicator(),
              ),

            if (selectedImage != null &&
                !scanning)

              GlassCard(

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Center(

                      child: ClipRRect(

                        borderRadius:
                        BorderRadius.circular(20),

                        child: Image.file(

                          selectedImage!,

                          height: 180,

                          width: 180,

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(

                      child: Text(

                        detectedFood,

                        style:
                        const TextStyle(

                          fontSize: 24,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(

                      child: Text(

                        'AI detected your meal successfully',

                        style: TextStyle(
                          color:
                          Colors.grey.shade600,
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