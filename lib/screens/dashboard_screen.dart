import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calorie_journal.dart';
import '../providers/medicine_catalog.dart';
import '../services/auth_service.dart';
import '../services/medicine_stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

import 'login_screen.dart';
import 'settings_screen.dart';
import 'medication_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.goTab,
  });

  final void Function(int tab) goTab;

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will return to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicineCatalog>().items;

    final kcal = context.watch<CalorieJournal>().todayTotal;

    final email =
        FirebaseAuth.instance.currentUser?.email ?? '';

    final name = email.contains('@')
        ? email.split('@').first
        : 'there';

    return Scaffold(
      backgroundColor: AppTheme.mintGlow,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// HEADER
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $name 👋',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Your wellness hub',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),

                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 6),

                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// INFO CARD
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius:
                        BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        Icons.offline_bolt_rounded,
                        color: Colors.teal,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Text(
                        'Medicines and meals are stored locally on this device.',
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// STATS
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Active reminders',
                      value: '${meds.length}',
                      icon: Icons.alarm_rounded,
                      onTap: () => goTab(1),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: StatCard(
                      label: "Today's kcal",
                      value: '$kcal',
                      icon:
                      Icons.local_fire_department_rounded,
                      gradient: AppTheme.coralGradient,
                      onTap: () => goTab(3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const MedicationHistoryScreen(),
                    ),
                  );
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        const Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Medication Adherence',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          '${MedicineStatsService.adherencePercent().toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 12),

                        LinearProgressIndicator(
                          value:
                          MedicineStatsService
                              .adherencePercent() /
                              100,
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [

                            _stat(
                              '✓',
                              MedicineStatsService
                                  .takenCount(),
                              'Taken',
                            ),

                            _stat(
                              '✗',
                              MedicineStatsService
                                  .skippedCount(),
                              'Missed',
                            ),

                            _stat(
                              '⏰',
                              MedicineStatsService
                                  .snoozedCount(),
                              'Snoozed',
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          'Tap to view history',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    const SizedBox(height: 20),

    /// QUICK ACTIONS
              Text(
                'Quick actions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              FeatureRow(
                title: 'Medicine reminders',
                subtitle:
                'Schedule daily local notifications',
                icon: Icons.medication_liquid_rounded,
                onTap: () => goTab(1),
              ),

              FeatureRow(
                title: 'Guided breathing',
                subtitle:
                'Relax with breathing exercise',
                icon: Icons.spa_rounded,
                onTap: () => goTab(2),
              ),

              FeatureRow(
                title: 'Nutrition log',
                subtitle:
                'Track meals and calories',
                icon: Icons.restaurant_menu_rounded,
                onTap: () => goTab(3),
              ),

              FeatureRow(
                title: 'MediCoach',
                subtitle:
                'AI + voice assistant support',
                icon: Icons.auto_awesome_rounded,
                onTap: () => goTab(4),
              ),

              const SizedBox(height: 24),

              /// LOGOUT
              GestureDetector(
                onTap: () => _logout(context),

                child: Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign out',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Switch account on this device',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
Widget _stat(
    String icon,
    int value,
    String label,
    ) {
  return Column(
    children: [

      Text(
        icon,
        style: const TextStyle(
          fontSize: 22,
        ),
      ),

      Text(
        '$value',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      Text(label),
    ],
  );
}