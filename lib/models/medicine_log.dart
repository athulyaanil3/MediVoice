enum MedicineStatus {
  taken,
  skipped,
  snoozed,
}

class MedicineLog {
  final String medicineId;
  final String medicineName;
  final DateTime time;
  final MedicineStatus status;

  MedicineLog({
    required this.medicineId,
    this.medicineName= '',
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'time': time.toIso8601String(),
      'status': status.name,
    };
  }

  factory MedicineLog.fromMap(
      Map<String, dynamic> map) {
    return MedicineLog(
      medicineId: map['medicineId'],
      medicineName:
      map['medicineName'] ?? '',
      time: DateTime.parse(
        map['time'],
      ),
      status: MedicineStatus.values.firstWhere(
            (e) => e.name == map['status'],
      ),
    );
  }
}