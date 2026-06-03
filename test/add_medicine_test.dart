import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medic/providers/medicine_catalog.dart';
import 'package:medic/services/local_store.dart';
import 'package:medic/screens/medicines_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
  });

  tearDown(() async {
    // No teardown required for shared preferences mock
  });

  testWidgets('Save medicine test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final catalog = MedicineCatalog();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MedicineCatalog>.value(value: catalog),
          ],
          child: const MedicinesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Add medicine"
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Fill in the medicine name
    await tester.enterText(find.bySemanticsLabel('Medicine name *'), 'Aspirin');
    await tester.pumpAndSettle();

    // Tap "Add time"
    await tester.tap(find.text('Add time'));
    await tester.pumpAndSettle();

    // Tap OK on the time picker dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tap "Save medicine"
    await tester.tap(find.text('Save medicine'));
    await tester.pumpAndSettle();

    // Let's print out if there was any error or if catalog has the item
    print("Catalog count: ${catalog.count}");
    if (catalog.count > 0) {
      print("Medicine name: ${catalog.items.first.name}");
    }
  });
}
