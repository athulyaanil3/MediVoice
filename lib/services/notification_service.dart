import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';
import '../utils/reminder_time.dart';
import 'reminder_voice_alarm.dart';
import 'reminder_voice_service.dart';

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

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  speakFromNotificationPayload(response.payload);
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
    await initReminderVoiceAlarms();
  } catch (e) {
    if (kDebugMode) debugPrint('Voice alarm init skipped: $e');
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  await _notifications.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      speakFromNotificationPayload(response.payload);
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

  final launch = await _notifications.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp == true) {
    speakFromNotificationPayload(launch?.notificationResponse?.payload);
  }
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
