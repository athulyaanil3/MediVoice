import '../models/medicine_log.dart';
import 'local_store.dart';

class MedicineStatsService {
  static double adherencePercent() {
    final logs = LocalStore.readMedicineLogs();

    if (logs.isEmpty) {
      return 0;
    }

    final taken = logs
        .where(
          (e) => e.status == MedicineStatus.taken,
    )
        .length;

    return (taken / logs.length) * 100;
  }

  static int takenCount() {
    return LocalStore.readMedicineLogs()
        .where(
          (e) => e.status == MedicineStatus.taken,
    )
        .length;
  }

  static int skippedCount() {
    return LocalStore.readMedicineLogs()
        .where(
          (e) => e.status == MedicineStatus.skipped,
    )
        .length;
  }

  static int snoozedCount() {
    return LocalStore.readMedicineLogs()
        .where(
          (e) => e.status == MedicineStatus.snoozed,
    )
        .length;
  }
}