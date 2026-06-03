import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../services/local_store.dart';
import '../utils/reminder_time.dart';
import 'reminder_voice_alarm.dart';
import 'reminder_voice_service.dart';
import '../main.dart';
import '../screens/remainder_response_screen.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? get _android {
  try {
    return _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
  } catch (_) {
    return null;
  }
}

int preAlarmNotificationId(String medicineId, int slotIndex) {
  final combined = Object.hash(medicineId, slotIndex, 'pre_alarm');
  return (combined & 0x7fffffff).clamp(1, 2147483646);
}

int snoozeReminderId(String medicineId) {
  final combined = Object.hash(medicineId, 'snooze_reminder');
  return (combined & 0x7fffffff).clamp(1, 2147483646);
}

int snoozeStatusId(String medicineId) {
  final combined = Object.hash(medicineId, 'snooze_status');
  return (combined & 0x7fffffff).clamp(1, 2147483646);
}

Future<void> skipReminderOccurrenceToday(String medicineId, int slotIndex) async {
  try {
    if (!HiveBoxesReady.check()) {
      await LocalStore.boot();
    }
    final medicines = LocalStore.readMedicines();
    final medicine = medicines.firstWhere((m) => m.id == medicineId);

    final id = reminderNotificationId(medicine.id, slotIndex);
    await _notifications.cancel(id);
    await cancelVoiceAlarm(id);

    // Save to logs as skipped
    await LocalStore.saveMedicineLog(
      MedicineLog(
        medicineId: medicineId,
        medicineName: medicine.name,
        time: DateTime.now(),
        status: MedicineStatus.skipped,
      ),
    );

    // Re-schedule starting from tomorrow
    final parsed = parseReminderTime(medicine.reminderTimes[slotIndex]);
    if (parsed != null) {
      final now = tz.TZDateTime.now(tz.local);
      final tomorrow = now.add(const Duration(days: 1));
      final when = tz.TZDateTime(
        tz.local,
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        parsed.hour,
        parsed.minute,
      );

      final canExact = defaultTargetPlatform == TargetPlatform.android
          ? (await _android?.canScheduleExactNotifications() ?? false)
          : true;

      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final speechText = ReminderVoiceService.buildMessage(medicine);
      final timeStr = displayReminderTime(medicine.reminderTimes[slotIndex]);
      final payload = _notificationPayload(medicine);

      // Reschedule the pre-alarm for tomorrow as well!
      final preAlarmId = preAlarmNotificationId(medicine.id, slotIndex);
      final preAlarmWhen = when.subtract(const Duration(minutes: 15));
      if (preAlarmWhen.isAfter(now)) {
        final preAlarmAndroidDetails = AndroidNotificationDetails(
          'medic_reminders_v1',
          'Medicine reminders',
          channelDescription: 'Daily medicine reminder times',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'action_pre_alarm_stop',
              'Stop',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        );

        final preAlarmPayload = jsonEncode({
          'id': medicine.id,
          'slotIndex': slotIndex,
        });

        await _notifications.zonedSchedule(
          preAlarmId,
          'Clock',
          'The $timeStr alarm will ring soon.',
          preAlarmWhen,
          NotificationDetails(
            android: preAlarmAndroidDetails,
            iOS: iosDetails,
          ),
          payload: preAlarmPayload,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      final androidDetails = AndroidNotificationDetails(
        'medic_reminders_v1',
        'Medicine reminders',
        channelDescription: 'Daily medicine reminder times',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          medicine.dosage.isEmpty ? speechText : '${medicine.dosage}\n$speechText',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'action_snooze',
            'Snooze',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'action_skip',
            '✗ Skip',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      await _notifications.zonedSchedule(
        id,
        timeStr,
        '💊 Alarm - ${medicine.name}',
        when,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      try {
        await scheduleVoiceAlarmForReminder(
          alarmId: id,
          when: when,
          speechText: speechText,
          hour: parsed.hour,
          minute: parsed.minute,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Voice alarm skipped on reschedule: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error skipping reminder today: $e');
    }
  }
}

Future<void> handleNotificationAction(String actionId, String payload) async {
  try {
    if (!HiveBoxesReady.check()) {
      await LocalStore.boot();
    }
    final data = jsonDecode(payload);
    final String medicineId = data['id'] ?? '';
    final String medicineName = data['name'] ?? 'Medicine';

    if (actionId == 'action_taken') {
      await LocalStore.saveMedicineLog(
        MedicineLog(
          medicineId: medicineId,
          medicineName: medicineName,
          time: DateTime.now(),
          status: MedicineStatus.taken,
        ),
      );
    } else if (actionId == 'action_skip') {
      await LocalStore.saveMedicineLog(
        MedicineLog(
          medicineId: medicineId,
           medicineName: medicineName,
          time: DateTime.now(),
          status: MedicineStatus.skipped,
        ),
      );
    } else if (actionId == 'action_snooze') {
      await LocalStore.saveMedicineLog(
        MedicineLog(
          medicineId: medicineId,
          medicineName: medicineName,
          time: DateTime.now(),
          status: MedicineStatus.snoozed,
        ),
      );

      final delay = const Duration(minutes: 10);
      final reminderId = snoozeReminderId(medicineId);
      final statusId = snoozeStatusId(medicineId);

      await scheduleSnoozeReminder(
        notificationId: reminderId,
        title: '💊 $medicineName',
        body: 'Medicine reminder',
        payload: payload,
        delay: delay,
      );

      await _notifications.show(
        statusId,
        'Snooze',
        '$medicineName reminder',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medic_reminders_v1',
            'Medicine reminders',
            importance: Importance.low,
            usesChronometer: true,
            chronometerCountDown: true,
            when: DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'action_cancel_snooze',
                'X',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: payload,
      );
    } else if (actionId == 'action_cancel_snooze') {
      final statusId = snoozeStatusId(medicineId);
      await _notifications.cancel(statusId);

      final reminderId = snoozeReminderId(medicineId);
      await _notifications.cancel(reminderId);
      await cancelVoiceAlarm(reminderId);
    } else if (actionId == 'action_pre_alarm_stop') {
      final int slotIndex = data['slotIndex'] ?? 0;
      final preAlarmId = preAlarmNotificationId(medicineId, slotIndex);
      await _notifications.cancel(preAlarmId);
      await skipReminderOccurrenceToday(medicineId, slotIndex);
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error handling notification action: $e');
    }
  }
}

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  speakFromNotificationPayload(response.payload);
  if (response.payload != null && response.actionId != null) {
    await handleNotificationAction(response.actionId!, response.payload!);
  }
}

/// Permission status for reminders
class ReminderPermissionStatus {
  const ReminderPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;

  bool get ready => notificationsEnabled;

  String? get setupHint {
    if (!notificationsEnabled) {
      return 'Turn on notifications for MediVoice in system settings.';
    }
    if (!exactAlarmsEnabled) {
      return 'Allow alarms & reminders so doses fire at the exact time you set.';
    }
    return null;
  }
}

class NotificationScheduleResult {
  const NotificationScheduleResult({
    required this.ok,
    this.message,
    this.scheduledCount = 0,
  });

  final bool ok;
  final String? message;
  final int scheduledCount;
}

Future<void> initNotifications() async {
  tz_data.initializeTimeZones();
  await _configureLocalTimeZone();

  try {
    // await initReminderVoiceAlarms();
  } catch (e) {
    if (kDebugMode) debugPrint('Voice alarm init skipped: $e');
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  await _notifications.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) async {
      if (response.payload != null) {
        if (response.actionId != null) {
          await handleNotificationAction(response.actionId!, response.payload!);
        } else {
          try {
            final data = jsonDecode(response.payload!);
            final String medicineId = data['id'] ?? '';
            final String medicineName = data['name'] ?? 'Medicine';
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ReminderResponseScreen(
                  medicineId: medicineId,
                  medicineName: medicineName,
                  payload: response.payload!,
                  notificationId: response.id ?? 0,
                ),
              ),
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Payload parse error: $e');
            }
          }
        }
      }
    },
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
  );

  const channel = AndroidNotificationChannel(
    'medic_reminders_v1',
    'Medicine reminders',
    description: 'Daily medicine dose reminders with voice',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await _android?.createNotificationChannel(channel);
  await ensureReminderPermissions(requestIfNeeded: true);
}

Future<void> _configureLocalTimeZone() async {
  try {
    final TimezoneInfo timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    if (kDebugMode) {
      debugPrint('Notification timezone: ${timezone.identifier}');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Timezone setup failed: $e');
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }
}

Future<ReminderPermissionStatus> getReminderPermissionStatus() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final notificationsEnabled =
        await _android?.areNotificationsEnabled() ?? false;
    final exactAlarmsEnabled =
        await _android?.canScheduleExactNotifications() ?? false;
    return ReminderPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsEnabled: exactAlarmsEnabled,
    );
  }
  final notif = await Permission.notification.status;
  return ReminderPermissionStatus(
    notificationsEnabled: notif.isGranted,
    exactAlarmsEnabled: true,
  );
}

Future<ReminderPermissionStatus> ensureReminderPermissions({
  bool requestIfNeeded = true,
}) async {
  if (requestIfNeeded) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _android?.requestNotificationsPermission();
      final exact = await Permission.scheduleExactAlarm.status;
      if (!exact.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
      final notif = await Permission.notification.status;
      if (!notif.isGranted) {
        await Permission.notification.request();
      }
    } else {
      await Permission.notification.request();
    }
  }
  return getReminderPermissionStatus();
}

Future<void> openReminderPermissionSettings() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final status = await getReminderPermissionStatus();
    if (!status.notificationsEnabled) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return;
    }
    if (!status.exactAlarmsEnabled) {
      await AppSettings.openAppSettings(type: AppSettingsType.alarm);
      return;
    }
  }
  await openAppSettings();
}

/// Opens battery settings — needed on Oppo/Realme/Vivo so alarms fire on time.
Future<void> openBatteryOptimizationSettings() async {
  await AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
}

int reminderNotificationId(String medicineId, int slotIndex) {
  final combined = Object.hash(medicineId, slotIndex);
  return (combined & 0x7fffffff).clamp(1, 2147483646);
}

String _notificationPayload(Medicine medicine) => jsonEncode({
      'id': medicine.id,
      'name': medicine.name,
      'dosage': medicine.dosage,
    });

Future<void> cancelMedicineNotifications(Medicine medicine) async {
  for (var i = 0; i < medicine.reminderTimes.length; i++) {
    final id = reminderNotificationId(medicine.id, i);
    await _notifications.cancel(id);
    await cancelVoiceAlarm(id);
  }
}

Future<void> cancelAllMedicineReminders() async {
  await _notifications.cancelAll();
}

Future<void> rescheduleAllMedicineNotifications(List<Medicine> medicines) async {
  await cancelAllMedicineReminders();
  for (final medicine in medicines) {
    await scheduleMedicineNotifications(medicine);
  }
}

Future<NotificationScheduleResult> scheduleMedicineNotifications(
  Medicine medicine,
) async {
  final permission = await ensureReminderPermissions(requestIfNeeded: true);

  if (!permission.ready) {
    return NotificationScheduleResult(
      ok: false,
      message: permission.setupHint ?? 'Enable notifications to get reminders.',
    );
  }

  final canExact = defaultTargetPlatform == TargetPlatform.android
      ? (await _android?.canScheduleExactNotifications() ?? false)
      : true;

  final scheduleMode = canExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    presentBadge: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  final speechText = ReminderVoiceService.buildMessage(medicine);
  var scheduled = 0;
  String? lastError;

  for (var i = 0; i < medicine.reminderTimes.length; i++) {
    final parsed = parseReminderTime(medicine.reminderTimes[i]);
    if (parsed == null) {
      if (kDebugMode) {
        debugPrint(
          'Skip invalid reminder time "${medicine.reminderTimes[i]}" for ${medicine.name}',
        );
      }
      continue;
    }

    final when = _nextOccurrence(parsed.hour, parsed.minute);
    final id = reminderNotificationId(medicine.id, i);
    final payload = _notificationPayload(medicine);

    final androidDetails = AndroidNotificationDetails(
      'medic_reminders_v1',
      'Medicine reminders',
      channelDescription: 'Daily medicine reminder times',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        medicine.dosage.isEmpty ? speechText : '${medicine.dosage}\n$speechText',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_taken',
          '✓ Taken',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_snooze',
          '⏰ Snooze',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_skip',
          '✗ Skip',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        '💊 ${medicine.name}',
        medicine.dosage.isNotEmpty ? medicine.dosage : speechText,
        when,
        details,
        payload: payload,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      scheduled++;

      try {
        await scheduleVoiceAlarmForReminder(
          alarmId: id,
          when: when,
          speechText: speechText,
          hour: parsed.hour,
          minute: parsed.minute,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Voice alarm skipped for ${medicine.name}: $e');
      }

      if (kDebugMode) {
        debugPrint(
          'Scheduled ${medicine.name} at ${medicine.reminderTimes[i]} → $when',
        );
      }
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) debugPrint('Scheduling failed: $e');
    }
  }

  if (scheduled == 0) {
    return NotificationScheduleResult(
      ok: false,
      message: lastError ?? 'Could not schedule reminders.',
    );
  }

  if (!permission.exactAlarmsEnabled) {
    return NotificationScheduleResult(
      ok: true,
      scheduledCount: scheduled,
      message: 'Reminders set with voice (${ReminderVoiceService.languageTag()}). Allow exact alarms for precise timing.',
    );
  }

  return NotificationScheduleResult(
    ok: true,
    scheduledCount: scheduled,
    message: 'Reminders set with local voice alert.',
  );
}

tz.TZDateTime _nextOccurrence(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (scheduled.isBefore(now)) {
    final lateBy = now.difference(scheduled);
    if (lateBy.inMinutes < 3) {
      return now.add(const Duration(seconds: 15));
    }
    scheduled = scheduled.add(const Duration(days: 1));
  }

  return scheduled;
}

Future<void> showTestReminderNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'medic_reminders_v1',
    'Medicine reminders',
    importance: Importance.max,
    priority: Priority.high,
  );

  const testSpeech = 'This is a test medicine reminder.';

  await _notifications.show(
    999001,
    '💊 Test reminder',
    testSpeech,
    const NotificationDetails(android: androidDetails),
  );

  await ReminderVoiceService.speak(
    ReminderVoiceService.buildMessageFromParts(
      name: 'Test medicine',
      dosage: 'one tablet',
    ),
  );
}
Future<void> scheduleSnoozeReminder({
  required int notificationId,
  required String title,
  required String body,
  required String payload,
  required Duration delay,
}) async {


  final when = tz.TZDateTime.now(tz.local);

  await _notifications.zonedSchedule(
    notificationId,
    title,
    body,
    when,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'medic_reminders_v1',
        'Medicine reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    payload: payload,
    androidScheduleMode:
    AndroidScheduleMode.exactAllowWhileIdle,
  );
}

Future<void> cancelNotificationById(
    int notificationId,
    ) async {
  await _notifications.cancel(
    notificationId,
  );
}

