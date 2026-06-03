import '../models/medicine_log.dart';
import 'local_store.dart';

class AdherenceService {

  static double percentage() {

    final logs =
    LocalStore
        .readMedicineLogs();

    if (logs.isEmpty) {
      return 0;
    }

    final taken =
        logs.where(
              (e) =>
          e.status ==
              MedicineStatus.taken,
        ).length;

    final skipped =
        logs.where(
              (e) =>
          e.status ==
              MedicineStatus.skipped,
        ).length;

    final total =
        taken + skipped;

    if (total == 0) {
      return 0;
    }

    return (taken / total) * 100;
  }

  static double adherencePercent() {
    return percentage();
  }

  static int takenCount() {
    final logs = LocalStore.readMedicineLogs();
    return logs.where((e) => e.status == MedicineStatus.taken).length;
  }

  static int skippedCount() {
    final logs = LocalStore.readMedicineLogs();
    return logs.where((e) => e.status == MedicineStatus.skipped).length;
  }
}