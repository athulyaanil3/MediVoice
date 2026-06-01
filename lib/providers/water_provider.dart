import 'package:flutter/material.dart';

class WaterProvider extends ChangeNotifier {

  double waterGoal = 3.0;
  double waterIntake = 0.0;

  void setGoal(double goal) {
    waterGoal = goal;
    notifyListeners();
  }

  void addWater(double amount) {

    waterIntake += amount;

    if (waterIntake > waterGoal) {
      waterIntake = waterGoal;
    }

    notifyListeners();
  }

  double get progress =>
      waterIntake / waterGoal;

  bool get completed =>
      waterIntake >= waterGoal;
  void removeWater(double amount) {

    waterIntake -= amount;

    if (waterIntake < 0) {

      waterIntake = 0;
    }

    notifyListeners();
  }
}