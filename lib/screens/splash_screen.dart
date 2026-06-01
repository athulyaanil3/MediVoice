import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_catalog.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _route();
  }

  Future<void> _route() async {
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 1600));
    final user = await AuthService().waitForSignedInUser();
    await minSplash;
    if (!mounted) return;

    if (user != null) {
      await context.read<MedicineCatalog>().syncWithCloudAndReschedule();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.scaffoldGradient(context),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.06).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: [AppTheme.softShadow(0.3)],
                    ),
                    child: const Icon(
                      Icons.medication_liquid_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'MediVoice AI',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Smart medicine · calm mind · healthy habits',
                    style: TextStyle(color: AppTheme.inkMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.deepTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
