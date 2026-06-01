import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {

  final String id;
  final String name;
  final String dosage;

  final List<String> reminderTimes;
  final List<String> repeatDays;

  final int stock;
  final int dailyDose;

  final String? notes;

  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.reminderTimes,
    required this.repeatDays,
    required this.stock,
    required this.dailyDose,
    this.notes,
    DateTime? createdAt,
  }) : createdAt =
      createdAt ?? DateTime.now();

  // =========================
  // TO MAP
  // =========================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'reminderTimes': reminderTimes,
      'repeatDays': repeatDays,
      'stock': stock,
      'dailyDose': dailyDose,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'reminderTimes': reminderTimes,
      'repeatDays': repeatDays,
      'stock': stock,
      'dailyDose': dailyDose,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // =========================
  // FROM MAP
  // =========================

  factory Medicine.fromMap(
      Map<String, dynamic> raw,
      ) {

    // REMINDER TIMES

    List<String> reminderTimes = [];

    if (raw['reminderTimes'] is List) {

      reminderTimes =
      List<String>.from(
        raw['reminderTimes'],
      );

    } else if (raw['reminderTimes'] != null) {

      reminderTimes = [
        raw['reminderTimes']
            .toString()
      ];
    }

    // REPEAT DAYS

    List<String> repeatDays = [];

    if (raw['repeatDays'] is List) {

      repeatDays =
      List<String>.from(
        raw['repeatDays'],
      );

    } else if (raw['repeatDays'] != null) {

      repeatDays = [
        raw['repeatDays']
            .toString()
      ];
    }

    // CREATED AT

    DateTime createdAt =
    DateTime.now();

    final createdRaw =
    raw['createdAt'];

    if (createdRaw
    is Timestamp) {

      createdAt =
          createdRaw.toDate();

    } else if (createdRaw
    is String) {

      createdAt =
          DateTime.tryParse(
            createdRaw,
          ) ??
              DateTime.now();
    }

    return Medicine(

      id:
      raw['id']
          ?.toString() ??
          '',

      name:
      raw['name']
          ?.toString() ??
          '',

      dosage:
      raw['dosage']
          ?.toString() ??
          '',

      reminderTimes:
      reminderTimes,

      repeatDays:
      repeatDays,

      stock:
      raw['stock'] is int
          ? raw['stock']
          : int.tryParse(
          raw['stock']
              ?.toString() ??
              '0') ??
          0,

      dailyDose:
      raw['dailyDose']
      is int
          ? raw['dailyDose']
          : int.tryParse(
          raw['dailyDose']
              ?.toString() ??
              '0') ??
          0,

      notes:
      raw['notes']
          ?.toString(),

      createdAt:
      createdAt,
    );
  }
}