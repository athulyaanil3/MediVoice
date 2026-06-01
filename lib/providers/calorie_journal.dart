import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../services/local_store.dart';

class CalorieJournal extends ChangeNotifier {
  CalorieJournal() {
    reload();
  }

  static const mlPerGlass = 250;

  final _uuid = const Uuid();
  List<FoodEntry> _entries = [];

  int _calorieGoal = LocalStore.defaultCalorieGoal;
  int _waterGoalMl = LocalStore.defaultWaterGoalMl;
  int _waterMlToday = 0;

  List<FoodEntry> get entries => List.unmodifiable(_entries);
  int get calorieGoal => _calorieGoal;
  int get waterGoalMl => _waterGoalMl;
  int get waterMlToday => _waterMlToday;
  double get waterLitersToday => _waterMlToday / 1000;
  double get waterGoalLiters => _waterGoalMl / 1000;
  int get waterGlassesToday => (_waterMlToday / mlPerGlass).floor();
  int get waterGlassGoal => (_waterGoalMl / mlPerGlass).ceil();

  int get todayTotal => LocalStore.todayCalorieTotal();

  List<FoodEntry> get todayEntries => LocalStore.readToday();

  double get todayProgress =>
      _calorieGoal <= 0 ? 0 : (todayTotal / _calorieGoal).clamp(0.0, 1.2);

  int get caloriesRemaining => (_calorieGoal - todayTotal).clamp(0, _calorieGoal);

  bool get isOverGoal => todayTotal > _calorieGoal;

  int get weekAverage {
    final totals = last7DailyTotals();
    if (totals.isEmpty) return 0;
    return (totals.values.fold<int>(0, (a, b) => a + b) / totals.length).round();
  }

  FoodEntry? get lastMeal => LocalStore.lastLoggedMeal();

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<String, int> get todayByMeal {
    final map = {'Breakfast': 0, 'Lunch': 0, 'Dinner': 0, 'Snack': 0};
    for (final e in todayEntries) {
      final key = map.containsKey(e.meal) ? e.meal! : 'Snack';
      map[key] = (map[key] ?? 0) + e.calories;
    }
    return map;
  }

  void reload() {
    try {
      _calorieGoal = LocalStore.readCalorieGoal();
      _waterMlToday = LocalStore.readWaterMlToday();
      final since = _dayStart(DateTime.now()).subtract(const Duration(days: 6));
      _entries = LocalStore.readFoodSince(since);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CalorieJournal.reload: $e');
      }
      _entries = [];
    }
    notifyListeners();
  }

  Future<void> setCalorieGoal(int goal) async {
    await LocalStore.writeCalorieGoal(goal);
    _calorieGoal = LocalStore.readCalorieGoal();
    notifyListeners();
  }

  Future<void> addWater({int ml = mlPerGlass}) async {
    _waterMlToday = (_waterMlToday + ml).clamp(0, 6000);
    await LocalStore.writeWaterMlToday(_waterMlToday);
    notifyListeners();
  }

  Future<void> removeWater({int ml = mlPerGlass}) async {
    _waterMlToday = (_waterMlToday - ml).clamp(0, 6000);
    await LocalStore.writeWaterMlToday(_waterMlToday);
    notifyListeners();
  }

  Future<FoodEntry> addEntry({
    required String label,
    required int calories,
    String? meal,
  }) async {
    final entry = FoodEntry(
      id: _uuid.v4(),
      label: label.trim(),
      calories: calories.abs(),
      meal: meal,
    );
    await LocalStore.upsertFood(entry);
    reload();
    return entry;
  }

  Future<void> repeatLastMeal() async {
    final last = lastMeal;
    if (last == null) return;
    await addEntry(
      label: last.label,
      calories: last.calories,
      meal: last.meal,
    );
  }

  Future<void> deleteEntry(String id) async {
    await LocalStore.deleteFood(id);
    reload();
  }

  Map<DateTime, int> last7DailyTotals() {
    final totals = <DateTime, int>{};
    final today = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final day = _dayStart(today).subtract(Duration(days: i));
      totals[day] = LocalStore.readFoodSince(day).fold<int>(0, (s, e) {
        return _dayStart(e.at) == day ? s + e.calories : s;
      });
    }
    return totals;
  }

  ({DateTime day, int kcal})? get bestDayThisWeek {
    final totals = last7DailyTotals();
    if (totals.values.every((v) => v == 0)) return null;
    var bestDay = totals.keys.first;
    var best = totals[bestDay]!;
    for (final e in totals.entries) {
      if (e.value > best) {
        best = e.value;
        bestDay = e.key;
      }
    }
    return (day: bestDay, kcal: best);
  }
}
