import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medic/providers/calorie_journal.dart';
import 'package:medic/providers/water_provider.dart';
import 'package:medic/screens/nutrition_screen.dart';
import 'package:medic/services/local_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
  });

  tearDown(() async {
    // No teardown required for shared preferences mock
  });

  testWidgets('NutritionScreen builds with food entries and functions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final journal = CalorieJournal();
    final waterProvider = WaterProvider();

    await tester.runAsync(() async {
      await journal.addEntry(label: 'Oatmeal', calories: 300, meal: 'Breakfast');
      await journal.addEntry(label: 'Salad', calories: 150, meal: 'Lunch');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<CalorieJournal>.value(value: journal),
              ChangeNotifierProvider<WaterProvider>.value(value: waterProvider),
            ],
            child: const NutritionScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Food Log'), findsOneWidget);
    expect(find.text('Oatmeal'), findsOneWidget);
    expect(find.text('Salad'), findsOneWidget);

    // Tap 250 ml water
    await tester.tap(find.text('250 ml'));
    await tester.runAsync(() async {
      await tester.pump();
    });
    
    expect(waterProvider.waterIntake, 0.25);
  });
}
