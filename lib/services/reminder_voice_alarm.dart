import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_store.dart';
import 'reminder_voice_service.dart';

/// Android background alarm — speaks reminder in local language.
@pragma('vm:entry-point')
Future<void> fireReminderVoiceAlarm(int alarmId) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalStore.boot();
    if (!LocalStore.readVoiceRemindersEnabled()) return;

    final text = LocalStore.readReminderVoiceText(alarmId);
    if (text != null && text.isNotEmpty) {
      await ReminderVoiceService.speak(text);
    }

    final meta = LocalStore.readReminderVoiceMeta(alarmId);
    if (meta != null) {
      await _scheduleNextVoiceAlarm(
        alarmId: alarmId,
        hour: meta.hour,
        minute: meta.minute,
        speechText: text ?? '',
      );
    }
  } catch (e) {
    if (kDebugMode) debugPrint('fireReminderVoiceAlarm: $e');
  }
}

Future<void> initReminderVoiceAlarms() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await AndroidAlarmManager.initialize();
}

Future<void> scheduleVoiceAlarmForReminder({
  required int alarmId,
  required tz.TZDateTime when,
  required String speechText,
  required int hour,
  required int minute,
}) async {
  await LocalStore.writeReminderVoice(
    alarmId: alarmId,
    text: speechText,
    hour: hour,
    minute: minute,
  );

  if (defaultTargetPlatform != TargetPlatform.android) return;
  if (!LocalStore.readVoiceRemindersEnabled()) return;

  await _scheduleNextVoiceAlarm(
    alarmId: alarmId,
    hour: hour,
    minute: minute,
    speechText: speechText,
    firstAt: when,
  );
}

Future<void> cancelVoiceAlarm(int alarmId) async {
  await LocalStore.deleteReminderVoice(alarmId);
  if (defaultTargetPlatform == TargetPlatform.android) {
    await AndroidAlarmManager.cancel(alarmId);
  }
}

Future<void> _scheduleNextVoiceAlarm({
  required int alarmId,
  required int hour,
  required int minute,
  required String speechText,
  tz.TZDateTime? firstAt,
}) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  final when = firstAt ?? _nextOccurrence(hour, minute);
  final localWhen = DateTime(
    when.year,
    when.month,
    when.day,
    when.hour,
    when.minute,
  );

  await AndroidAlarmManager.oneShotAt(
    localWhen,
    alarmId,
    fireReminderVoiceAlarm,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
    allowWhileIdle: true,
  );

  if (kDebugMode) {
    debugPrint('Voice alarm $alarmId at $localWhen: $speechText');
  }
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
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

/// Parse notification payload JSON and speak.
Future<void> speakFromNotificationPayload(String? payload) async {
  if (payload == null || payload.isEmpty) return;
  if (!LocalStore.readVoiceRemindersEnabled()) return;

  try {
    if (!HiveBoxesReady.check()) {
      await LocalStore.boot();
    }
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final name = map['name']?.toString() ?? 'medicine';
    final dosage = map['dosage']?.toString() ?? '';
    final text = ReminderVoiceService.buildMessageFromParts(
      name: name,
      dosage: dosage,
    );
    await ReminderVoiceService.speak(text);
  } catch (e) {
    if (kDebugMode) debugPrint('speakFromNotificationPayload: $e');
  }
}

/// Quick check without throwing.
class HiveBoxesReady {
  static bool check() {
    try {
      return LocalStore.isInitialized;
    } catch (_) {
      return false;
    }
  }
}
