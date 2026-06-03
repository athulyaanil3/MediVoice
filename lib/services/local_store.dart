import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_entry.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';

class LocalStore {
  static const String medicinesKey = 'medicines';
  static const String medicinesBoxId = 'medicines';
  static const String foodBoxId = 'food_logs';
  static const String settingsBoxId = 'app_settings';
  static const String medicineLogsKey = 'medicine_logs';
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

  //
  static Future<void> clearMedicineLogs() async {
    await _prefs.remove(medicineLogsKey);
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
 // MEDICINE LOG

  static Future<void> saveMedicineLog(
      MedicineLog log,
      ) async {

    final logs = readMedicineLogs();

    logs.add(log);
    if (logs.length > 500) {
      logs.sort(
            (a, b) =>
            a.time.compareTo(
              b.time,
            ),
      );

      logs.removeRange(
        0,
        logs.length - 500,
      );
    }

    final encoded =
    logs.map((e) {
      return jsonEncode(
        e.toMap(),
      );
    }).toList();

    await _prefs.setStringList(
      medicineLogsKey,
      encoded,
    );
  }

  static List<MedicineLog>
  readMedicineLogs() {

    final data =
        _prefs.getStringList(
          medicineLogsKey,
        ) ??
            [];

    return data.map((e) {
      return MedicineLog.fromMap(
        jsonDecode(e),
      );
    }).toList();
  }

  // =========================
  // FOOD
  // =========================
  static Future<void> upsertFood(
      FoodEntry food,
      ) async {
    final foods = readFoodSince(
      DateTime(2000),
    );

    final index = foods.indexWhere(
          (f) => f.id == food.id,
    );

    if (index >= 0) {
      foods[index] = food;
    } else {
      foods.add(food);
    }

    final encoded = foods
        .map(
          (f) => jsonEncode(
        f.toMap(),
      ),
    )
        .toList();

    await _prefs.setStringList(
      foodBoxId,
      encoded,
    );
  }

  static Future<void> deleteFood(
      String id,
      ) async {
    final foods = readFoodSince(
      DateTime(2000),
    );

    foods.removeWhere(
          (f) => f.id == id,
    );

    final encoded = foods
        .map(
          (f) => jsonEncode(
        f.toMap(),
      ),
    )
        .toList();

    await _prefs.setStringList(
      foodBoxId,
      encoded,
    );
  }

  static List<FoodEntry> readFoodSince(
      DateTime from,
      ) {
    final data =
        _prefs.getStringList(
          foodBoxId,
        ) ??
            [];

    final foods = data
        .map(
          (e) => FoodEntry.fromMap(
        jsonDecode(e),
      ),
    )
        .toList();

    return foods
        .where(
          (f) => f.at.isAfter(from),
    )
        .toList();
  }

  static List<FoodEntry> readToday() {
    final now = DateTime.now();

    return readFoodSince(
      DateTime(
        now.year,
        now.month,
        now.day,
      ),
    );
  }

  static FoodEntry? lastLoggedMeal() {
    final foods = readFoodSince(
      DateTime(2000),
    );

    if (foods.isEmpty) return null;

    foods.sort(
          (a, b) => b.at.compareTo(a.at),
    );

    return foods.first;
  }

  static int todayCalorieTotal() {
    return readToday().fold<int>(
      0,
          (sum, food) =>
      sum + food.calories,
    );
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
// PROFILE DATA
// =========================

  static Future<void> saveUserProfile({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activity,
  }) async {
    await _prefs.setInt('user_age', age);
    await _prefs.setString('user_gender', gender);
    await _prefs.setDouble('user_weight', weight);
    await _prefs.setDouble('user_height', height);
    await _prefs.setString('user_activity', activity);
  }

  static Map<String, dynamic> readUserProfile() {
    return {
      'age': _prefs.getInt('user_age') ?? 0,
      'gender': _prefs.getString('user_gender') ?? 'Male',
      'weight': _prefs.getDouble('user_weight') ?? 0,
      'height': _prefs.getDouble('user_height') ?? 0,
      'activity':
      _prefs.getString('user_activity') ??
          'Moderately Active',
    };
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