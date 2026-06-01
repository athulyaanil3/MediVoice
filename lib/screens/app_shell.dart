import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'assistant_screen.dart';
import 'breathing_screen.dart';
import 'dashboard_screen.dart';
import 'medicines_screen.dart';
import 'nutrition_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  late final List<Widget> _pages = [
    DashboardScreen(goTab: (t) => setState(() => _tab = t)),
    const MedicinesScreen(),
    const BreathingScreen(),
    NutritionScreen(),
    const AssistantScreen(),
  ];

  static const _labels = ['Home', 'Meds', 'Breathe', 'Food', 'Coach'];
  static const _icons = [
    Icons.home_rounded,
    Icons.medication_liquid_rounded,
    Icons.spa_rounded,
    Icons.restaurant_rounded,
    Icons.auto_awesome_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mintGlow,
      body: IndexedStack(index: _tab, children: _pages),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white),
            boxShadow: [AppTheme.softShadow(0.14)],
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              for (var i = 0; i < _labels.length; i++)
                NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
            ],
          ),
        ),
      ),
    );
  }
}