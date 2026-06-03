import 'package:flutter/material.dart';

import '../models/medicine_log.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class ReminderResponseScreen extends StatelessWidget {
  final String medicineId;
  final String medicineName;
  final String payload;
  final int notificationId;

  const ReminderResponseScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
    required this.payload,
    required this.notificationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Reminder',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
            Text(
            medicineName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
          height: 20,
        ),

        const Text(
          'Did you take this medicine?',
        ),

        const SizedBox(
          height: 30,
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {

              await LocalStore.saveMedicineLog(
                MedicineLog(
                  medicineId: medicineId,
                  medicineName: medicineName,
                  time: DateTime.now(),
                  status: MedicineStatus.taken,
                ),
              );

              await cancelNotificationById(
                notificationId,
              );

              if (context.mounted) {
                Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                );
              }
            },
            child: const Text(
              '✓ Taken',
            ),
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {

              final TimeOfDay? selectedTime =
              await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (selectedTime == null) {
                return;
              }

              final now = DateTime.now();

              DateTime snoozeTime = DateTime(
                now.year,
                now.month,
                now.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              if (snoozeTime.isBefore(now)) {
                snoozeTime = snoozeTime.add(
                  const Duration(days: 1),
                );
              }

              final delay =
              snoozeTime.difference(now);

              await LocalStore.saveMedicineLog(
                MedicineLog(
                  medicineId: medicineId,
                  medicineName: medicineName,
                  time: DateTime.now(),
                  status: MedicineStatus.snoozed,
                ),
              );

              await scheduleSnoozeReminder(
                notificationId:
                DateTime.now()
                    .millisecondsSinceEpoch %
                    2147483647,
                title: '💊 $medicineName',
                body: 'Medicine reminder',
                payload: payload,
                delay: delay,
              );

              if (context.mounted) {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reminder snoozed until ${selectedTime.format(context)}',
                    ),
                  ),
                );

                Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                );
              }
            },


            child: const Text(
              '⏰ Remind Later',
            ),
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {

              await LocalStore.saveMedicineLog(
                MedicineLog(
                  medicineId: medicineId,
                  medicineName: medicineName,
                  time: DateTime.now(),
                  status: MedicineStatus.skipped,
                ),
              );

              await cancelNotificationById(
                notificationId,
              );

              if (context.mounted) {
                Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                );
              }
            },
            child: const Text(
              '✗ Skip',
            ),
          ),
        ),
        ],
      ),
    ),
    ),
    );
  }
}
