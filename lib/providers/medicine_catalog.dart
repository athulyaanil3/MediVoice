import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../models/medicine.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';
import '../utils/reminder_time.dart';

class MedicineCatalog extends ChangeNotifier {

  MedicineCatalog() {
    reload();
  }

  final _uuid = const Uuid();

  List<Medicine> _items = [];

  String? _lastScheduleMessage;

  List<Medicine> get items =>
      List.unmodifiable(_items);

  int get count => _items.length;

  // RELOAD LOCAL DATA

  void reload() {

    _items =
        LocalStore.readMedicines();

    notifyListeners();
  }

  /// Re-normalize times and reschedule all local notifications.
  Future<String?> rescheduleReminders() async {
    await _normalizeAllMedicineTimes();
    reload();
    await _rescheduleAllWithFeedback();
    _notifyAfterFrame();
    return _lastScheduleMessage;
  }

  // CLOUD SYNC

  Future<void>
  syncWithCloudAndReschedule()
  async {

    try {

      await CloudSyncService
          .instance
          .mergeFromCloud();

    } catch (e) {

      if (kDebugMode) {

        debugPrint(
          'Cloud sync: $e',
        );
      }
    }

    reload();

    await _normalizeAllMedicineTimes();
    reload();

    await _rescheduleAllWithFeedback();

    notifyListeners();
  }

  // ADD MEDICINE

  Future<String?> addMedicine({

    required String name,

    required String dosage,

    required List<String>
    reminderTimes,

    required List<String>
    repeatDays,

    // NEW
    required int stock,

    // NEW
    required int dailyDose,

    String? notes,

  }) async {

    if (name.trim().isEmpty) {

      return 'Medicine name is required.';
    }

    final normalizedTimes = normalizeReminderTimes(reminderTimes);

    if (normalizedTimes.isEmpty) {

      return 'Add at least one valid reminder time.';
    }

    final medicine =
    Medicine(

      id: _uuid.v4(),

      name: name.trim(),

      dosage: dosage.trim(),

      reminderTimes:
      normalizedTimes,

      repeatDays:
      repeatDays,

      // NEW
      stock: stock,

      // NEW
      dailyDose:
      dailyDose,

      notes:
      (notes == null ||
          notes.trim().isEmpty)

          ? null

          : notes.trim(),
    );

    // SAVE LOCAL

    await LocalStore
        .upsertMedicine(
      medicine,
    );

    _items =
        LocalStore.readMedicines();

    await _normalizeAllMedicineTimes();
    _items = LocalStore.readMedicines();

    // RESCHEDULE NOTIFICATIONS

    await _rescheduleAllWithFeedback();

    _notifyAfterFrame();

    // CLOUD PUSH

    unawaited(

      CloudSyncService.instance
          .pushMedicine(
        medicine,
      ),
    );

    return _lastScheduleMessage;
  }

  // EDIT MEDICINE

  Future<String?> replaceMedicine(

      Medicine old, {

        required String name,

        required String dosage,

        required List<String>
        reminderTimes,

        required List<String>
        repeatDays,

        // NEW
        required int stock,

        // NEW
        required int dailyDose,

        String? notes,

      }) async {

    // CANCEL OLD NOTIFICATIONS

    await cancelMedicineNotifications(
      old,
    );

    final normalizedTimes = normalizeReminderTimes(reminderTimes);

    if (normalizedTimes.isEmpty) {
      return 'Add at least one valid reminder time.';
    }

    final updated =
    Medicine(

      id: old.id,

      name: name.trim(),

      dosage: dosage.trim(),

      reminderTimes:
      normalizedTimes,

      repeatDays:
      repeatDays,

      // NEW
      stock: stock,

      // NEW
      dailyDose:
      dailyDose,

      notes:
      (notes == null ||
          notes.trim().isEmpty)

          ? null

          : notes.trim(),

      createdAt:
      old.createdAt,
    );

    // SAVE UPDATED

    await LocalStore
        .upsertMedicine(
      updated,
    );

    _items =
        LocalStore.readMedicines();

    await _normalizeAllMedicineTimes();
    _items = LocalStore.readMedicines();

    // RESCHEDULE

    await _rescheduleAllWithFeedback();

    _notifyAfterFrame();

    // CLOUD UPDATE

    unawaited(

      CloudSyncService.instance
          .pushMedicine(
        updated,
      ),
    );

    return _lastScheduleMessage;
  }

  // DELETE MEDICINE

  Future<void> removeMedicine(
      Medicine medicine,
      ) async {

    // CANCEL NOTIFICATIONS

    await cancelMedicineNotifications(
      medicine,
    );

    // DELETE LOCAL

    await LocalStore
        .deleteMedicine(
      medicine.id,
    );

    _items =
        LocalStore.readMedicines();

    // RESCHEDULE

    await _rescheduleAllWithFeedback();

    notifyListeners();

    // DELETE CLOUD

    unawaited(

      CloudSyncService.instance
          .deleteRemoteMedicine(
        medicine.id,
      ),
    );
  }

  // REDUCE STOCK

  Future<void> reduceStock(
      Medicine medicine,
      ) async {

    if (medicine.stock <= 0 || medicine.dailyDose <= 0) return;

    int updatedStock =
        medicine.stock -
            medicine.dailyDose;

    if (updatedStock < 0) {
      updatedStock = 0;
    }

    final updatedMedicine =
    Medicine(

      id: medicine.id,

      name: medicine.name,

      dosage: medicine.dosage,

      reminderTimes:
      medicine.reminderTimes,

      repeatDays:
      medicine.repeatDays,

      stock: updatedStock,

      dailyDose:
      medicine.dailyDose,

      notes:
      medicine.notes,

      createdAt:
      medicine.createdAt,
    );

    await LocalStore
        .upsertMedicine(
      updatedMedicine,
    );

    _items =
        LocalStore.readMedicines();

    notifyListeners();

    // LOW STOCK ALERT

    if (updatedStock <= 3) {

      if (kDebugMode) {

        debugPrint(
          '${medicine.name} stock is running low.',
        );
      }
    }
  }

  // RESCHEDULE ALL

  Future<void> _normalizeAllMedicineTimes() async {
    for (final m in _items) {
      final times = normalizeReminderTimes(m.reminderTimes);
      if (times.isEmpty) continue;

      var same = times.length == m.reminderTimes.length;
      if (same) {
        for (var i = 0; i < times.length; i++) {
          if (times[i] != m.reminderTimes[i]) {
            same = false;
            break;
          }
        }
      }
      if (same) continue;

      await LocalStore.upsertMedicine(
        Medicine(
          id: m.id,
          name: m.name,
          dosage: m.dosage,
          reminderTimes: times,
          repeatDays: m.repeatDays,
          stock: m.stock,
          dailyDose: m.dailyDose,
          notes: m.notes,
          createdAt: m.createdAt,
        ),
      );
    }
  }

  Future<void> _rescheduleAllWithFeedback() async {
    try {
      await cancelAllMedicineReminders();
      for (final m in _items) {
        await cancelMedicineNotifications(m);
      }

      var totalScheduled = 0;
      String? firstError;

      for (final m in _items) {
        final result = await scheduleMedicineNotifications(m);
        if (result.ok) {
          totalScheduled += result.scheduledCount;
        } else if (firstError == null) {
          firstError = result.message;
        }
      }

      final status = await getReminderPermissionStatus();

      if (!status.ready) {
        _lastScheduleMessage =
            status.setupHint ?? 'Enable notifications for reminders.';
      } else if (_items.isNotEmpty && totalScheduled == 0) {
        _lastScheduleMessage = firstError ??
            'Reminders not scheduled. Re-open each medicine and add a valid time (e.g. 8:00 AM).';
      } else if (totalScheduled > 0) {
        _lastScheduleMessage = 'Scheduled $totalScheduled reminder(s).';
        if (!status.exactAlarmsEnabled) {
          _lastScheduleMessage =
          '$totalScheduled reminder(s) set. Allow exact alarms for on-time alerts.';
        }
      } else {
        _lastScheduleMessage = null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Reschedule all: $e');
      }
      _lastScheduleMessage = 'Saved locally. Turn on notifications in Settings.';
    }
  }

  void _notifyAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      notifyListeners();
    });
  }
}