import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/food_entry.dart';
import '../models/medicine.dart';

class LocalStore {
  static const medicinesBoxId = 'medicines';
  static const foodBoxId = 'food_logs';

  /// Opens Hive and all boxes. Call from [main] before [runApp].
  static Future<void> boot() async {
    if (!Hive.isBoxOpen(medicinesBoxId) || !Hive.isBoxOpen(foodBoxId)) {
      await Hive.initFlutter();
      await Future.wait([
        if (!Hive.isBoxOpen(medicinesBoxId)) Hive.openBox(medicinesBoxId),
        if (!Hive.isBoxOpen(foodBoxId)) Hive.openBox(foodBoxId),
      ]);
    }
  }

  static Future<void> init() => boot();

  static Box _medBox() => Hive.box(medicinesBoxId);
  static Box _foodBox() => Hive.box(foodBoxId);

  static Future<void> upsertMedicine(Medicine m) async =>
      _medBox().put(m.id, jsonEncode(m.toMap()));

  static Future<void> deleteMedicine(String id) async => _medBox().delete(id);

  static List<Medicine> readMedicines() {
    final out = <Medicine>[];
    for (final key in _medBox().keys) {
      final raw = _medBox().get(key);
      if (raw is String) {
        out.add(Medicine.fromMap(jsonDecode(raw) as Map<String, dynamic>));
      }
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  static Future<void> upsertFood(FoodEntry e) async =>
      _foodBox().put(e.id, jsonEncode(e.toMap()));

  static Future<void> deleteFood(String id) async => _foodBox().delete(id);

  static List<FoodEntry> readFoodSince(DateTime from) {
    final out = <FoodEntry>[];
    for (final key in _foodBox().keys) {
      final raw = _foodBox().get(key);
      if (raw is String) {
        final entry = FoodEntry.fromMap(jsonDecode(raw) as Map<String, dynamic>);
        if (!entry.at.isBefore(from)) out.add(entry);
      }
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  static int todayCalorieTotal() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return readFoodSince(start).fold<int>(0, (s, e) => s + e.calories);
  }
}
