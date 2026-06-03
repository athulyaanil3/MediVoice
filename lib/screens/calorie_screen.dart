import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/water_provider.dart';
import '../services/food_service.dart';
import '../widgets/water_progress_widget.dart';

class CalorieScreen extends StatefulWidget {
  const CalorieScreen({super.key});

  @override
  State<CalorieScreen> createState() =>
      _CalorieScreenState();
}

class _CalorieScreenState
    extends State<CalorieScreen> {

  final TextEditingController controller =
  TextEditingController();

  Map<String, dynamic>? foodData;

  bool isLoading = false;

  File? selectedImage;

  Future<void> searchFood() async {

    setState(() {
      isLoading = true;
    });

    final result =
    await FoodAIService.getFoodDetails(
      controller.text,
    );

    setState(() {
      foodData = result;
      isLoading = false;
    });
  }

  Future<void> pickFoodImage() async {

    final picked =
    await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (picked != null) {

      setState(() {

        selectedImage =
            File(picked.path);
      });
    }
  }

  String getCalories() {

    if (foodData == null) return '0';

    return foodData!['calories']
        ?.toString() ??
        '0';
  }

  @override
  Widget build(BuildContext context) {

    final waterProvider =
    Provider.of<WaterProvider>(
      context,
    );

    return Scaffold(

      appBar: AppBar(
        title:
        const Text(
          'Food Log',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // FOOD SEARCH

            const Text(
              'Calorie Checker',

              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: controller,

              decoration: InputDecoration(

                hintText:
                'Search food...',

                prefixIcon:
                const Icon(
                  Icons.search,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: searchFood,

                child: const Text(
                  'Check Calories',
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (isLoading)
              const Center(
                child:
                CircularProgressIndicator(),
              ),

            if (foodData != null)

              Card(
                elevation: 5,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      16),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets.all(
                      16),

                  child: Column(

                    children: [

                      Text(
                        foodData![
                        'name'] ??
                            'Food',

                        style:
                        const TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      Text(
                        'Calories: ${getCalories()} kcal / 100g',

                        style:
                        const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // WATER TRACKER

            Card(
              elevation: 5,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                    16),
              ),

              child: Padding(
                padding:
                const EdgeInsets.all(
                    16),

                child: Column(

                  children: [

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                      children: [

                        const Text(
                          'Water Intake',

                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        IconButton(

                          icon: const Icon(
                            Icons.edit,
                          ),

                          onPressed: () {

                            final goalController =
                            TextEditingController();

                            showDialog(
                              context: context,

                              builder: (_) {

                                return AlertDialog(

                                  title:
                                  const Text(
                                    'Set Water Goal',
                                  ),

                                  content:
                                  TextField(
                                    controller:
                                    goalController,

                                    keyboardType:
                                    TextInputType
                                        .number,

                                    decoration:
                                    const InputDecoration(
                                      hintText:
                                      'Goal in Liters',
                                    ),
                                  ),

                                  actions: [

                                    TextButton(

                                      onPressed: () {

                                        double goal =
                                            double.tryParse(
                                              goalController
                                                  .text,
                                            ) ??
                                                3.0;

                                        waterProvider
                                            .setGoal(
                                          goal,
                                        );

                                        Navigator.pop(
                                            context);
                                      },

                                      child:
                                      const Text(
                                        'Save',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    WaterProgressWidget(
                      intake:
                      waterProvider
                          .waterIntake,

                      goal:
                      waterProvider
                          .waterGoal,
                    ),

                    const SizedBox(height: 20),

                    Row(

                      children: [

                        Expanded(
                          child:
                          ElevatedButton(

                            onPressed: () {

                              waterProvider
                                  .addWater(
                                0.25,
                              );
                            },

                            child:
                            const Text(
                              '+1 Glass',
                            ),
                          ),
                        ),

                        const SizedBox(
                            width: 10),

                        Expanded(
                          child:
                          ElevatedButton(

                            onPressed: () {

                              waterProvider
                                  .addWater(
                                0.5,
                              );
                            },

                            child:
                            const Text(
                              '+500 ml',
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (waterProvider
                        .completed)

                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 20,
                        ),

                        child: Column(

                          children: [

                            Icon(
                              Icons.celebration,
                              color:
                              Colors.green,
                              size: 50,
                            ),

                            SizedBox(
                                height: 10),

                            Text(
                              'Goal Completed 🎉',

                              style: TextStyle(
                                color:
                                Colors.green,

                                fontSize: 18,

                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // WEEKLY ANALYSIS

            const Text(
              'Weekly Water Analysis',

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 220,

              child: BarChart(

                BarChartData(

                  borderData:
                  FlBorderData(
                    show: false,
                  ),

                  titlesData:
                  FlTitlesData(
                    show: true,
                  ),

                  barGroups: [

                    BarChartGroupData(
                      x: 0,

                      barRods: [
                        BarChartRodData(
                          toY: 2,
                        ),
                      ],
                    ),

                    BarChartGroupData(
                      x: 1,

                      barRods: [
                        BarChartRodData(
                          toY: 3,
                        ),
                      ],
                    ),

                    BarChartGroupData(
                      x: 2,

                      barRods: [
                        BarChartRodData(
                          toY: 1.5,
                        ),
                      ],
                    ),

                    BarChartGroupData(
                      x: 3,

                      barRods: [
                        BarChartRodData(
                          toY: 2.5,
                        ),
                      ],
                    ),

                    BarChartGroupData(
                      x: 4,

                      barRods: [
                        BarChartRodData(
                          toY: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // AI FOOD SCANNER

            const Text(
              'AI Food Scanner',

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child:
              ElevatedButton.icon(

                onPressed:
                pickFoodImage,

                icon: const Icon(
                  Icons.camera_alt,
                ),

                label: const Text(
                  'Scan Food',
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (selectedImage != null)

              Column(

                children: [

                  ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                        16),

                    child: Image.file(
                      selectedImage!,

                      height: 220,

                      width:
                      double.infinity,

                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  Card(
                    elevation: 5,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          16),
                    ),

                    child: Padding(
                      padding:
                      const EdgeInsets
                          .all(16),

                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: const [

                          Text(
                            'Detected Food: Pizza',

                            style:
                            TextStyle(
                              fontSize: 20,

                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),

                          SizedBox(
                              height: 12),

                          Text(
                            'Calories: 320 kcal',
                          ),

                          Text(
                            'Protein: 12g',
                          ),

                          Text(
                            'Carbs: 40g',
                          ),

                          Text(
                            'Fat: 10g',
                          ),

                          SizedBox(
                              height: 10),

                          Text(
                            'Health Score: 8/10',

                            style:
                            TextStyle(
                              color:
                              Colors.green,

                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}