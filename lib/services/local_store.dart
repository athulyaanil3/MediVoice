import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_entry.dart';
import '../models/medicine.dart';

class LocalStore {
  static const String medicinesKey = 'medicines';
  static const String medicinesBoxId = 'medicines';
  static const String foodBoxId = 'food_logs';
  static const String settingsBoxId = 'app_settings';

  // DEFAULT VALUES

  static const int defaultCalorieGoal = 2000;

  static const int defaultWaterGoalMl = 3000;

  static late SharedPreferences _prefs;

  static bool get isInitialized => true;

  // =========================
  // INIT
  // =========================

  static Future<void> init() async {

    _prefs =
    await SharedPreferences.getInstance();
  }

  static Future<void> boot() async {
    await init();
  }

  // =========================
  // MEDICINES
  // =========================

  static Future<void> upsertMedicine(
      Medicine medicine,
      ) async {

    final medicines =
    readMedicines();

    final index =
    medicines.indexWhere(
          (m) => m.id == medicine.id,
    );

    if (index >= 0) {

      medicines[index] = medicine;

    } else {

      medicines.add(medicine);
    }

    final encoded =
    medicines.map((m) {

      return jsonEncode(
        m.toMap(),
      );

    }).toList();

    await _prefs.setStringList(
      medicinesKey,
      encoded,
    );
  }

  static Future<void> deleteMedicine(
      String id,
      ) async {

    final medicines =
    readMedicines();

    medicines.removeWhere(
          (m) => m.id == id,
    );

    final encoded =
    medicines.map((m) {

      return jsonEncode(
        m.toMap(),
      );

    }).toList();

    await _prefs.setStringList(
      medicinesKey,
      encoded,
    );
  }

  static List<Medicine> readMedicines() {

    final data =
        _prefs.getStringList(
          medicinesKey,
        ) ??
            [];

    return data.map((e) {

      return Medicine.fromMap(
        jsonDecode(e),
      );

    }).toList();
  }

  // =========================
  // FOOD
  // =========================

  static Future<void> upsertFood(
      FoodEntry food,
      ) async {}

  static Future<void> deleteFood(
      String id,
      ) async {}

  static List<FoodEntry> readFoodSince(
      DateTime from,
      ) {
    return [];
  }

  static List<FoodEntry> readToday() {
    return [];
  }

  static FoodEntry? lastLoggedMeal() {
    return null;
  }

  static int todayCalorieTotal() {
    return 0;
  }

  // =========================
  // CALORIE GOAL
  // =========================

  static int readCalorieGoal() {

    return _prefs.getInt(
      'calorie_goal',
    ) ??
        defaultCalorieGoal;
  }

  static Future<void> writeCalorieGoal(
      int goal,
      ) async {

    await _prefs.setInt(
      'calorie_goal',
      goal,
    );
  }

  // =========================
  // WATER
  // =========================

  static int readWaterMlToday() {

    return _prefs.getInt(
      'water_today',
    ) ??
        0;
  }

  static Future<void> writeWaterMlToday(
      int value,
      ) async {

    await _prefs.setInt(
      'water_today',
      value,
    );
  }

  static int readWaterGoal() {

    return _prefs.getInt(
      'water_goal',
    ) ??
        defaultWaterGoalMl;
  }

  static Future<void> writeWaterGoal(
      int goal,
      ) async {

    await _prefs.setInt(
      'water_goal',
      goal,
    );
  }

  // =========================
  // VOICE REMINDERS
  // =========================

  static bool readVoiceRemindersEnabled() {

    return _prefs.getBool(
      'voice_reminders',
    ) ??
        true;
  }

  static Future<void>
  writeVoiceRemindersEnabled(
      bool enabled,
      ) async {

    await _prefs.setBool(
      'voice_reminders',
      enabled,
    );
  }

  static Future<void> writeReminderVoice({
    required int alarmId,
    required String text,
    required int hour,
    required int minute,
  }) async {

    await _prefs.setString(
      'voice_$alarmId',
      text,
    );

    await _prefs.setInt(
      'voice_hour_$alarmId',
      hour,
    );

    await _prefs.setInt(
      'voice_minute_$alarmId',
      minute,
    );
  }

  static String? readReminderVoiceText(
      int alarmId,
      ) {

    return _prefs.getString(
      'voice_$alarmId',
    );
  }

  static ({int hour, int minute})?
  readReminderVoiceMeta(
      int alarmId,
      ) {

    final hour =
    _prefs.getInt(
      'voice_hour_$alarmId',
    );

    final minute =
    _prefs.getInt(
      'voice_minute_$alarmId',
    );

    if (hour == null ||
        minute == null) {

      return null;
    }

    return (
    hour: hour,
    minute: minute,
    );
  }

  static Future<void> deleteReminderVoice(
      int alarmId,
      ) async {

    await _prefs.remove(
      'voice_$alarmId',
    );

    await _prefs.remove(
      'voice_hour_$alarmId',
    );

    await _prefs.remove(
      'voice_minute_$alarmId',
    );
  }
}