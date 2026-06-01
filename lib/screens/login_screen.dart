import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_catalog.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/form_validators.dart';
import '../widgets/firebase_setup_dialog.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';
import '../widgets/validation_banner.dart';
import 'app_shell.dart';
import 'register_screen.dart';
import '../services/cloud_sync_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtr = TextEditingController();
  final _passCtr = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  String? _bannerMessage;

  Future<void> _goHome() async {

    try {

      // DOWNLOAD CLOUD DATA
      await CloudSyncService.instance
          .mergeFromCloud();

      // REFRESH PROVIDER
      await context
          .read<MedicineCatalog>()
          .syncWithCloudAndReschedule();

      // REALTIME CLOUD SYNC
      CloudSyncService.instance
          .watchMedicines()
          .listen((_) {});

    } catch (e) {
      debugPrint(
        'Cloud sync failed: $e',
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AppShell(),
      ),
    );
  }

  void _showError(String? message) {
    if (message == null || message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateEmailOnly() {
    final error = FormValidators.email(_emailCtr.text);
    setState(() => _bannerMessage = error);
    _formKey.currentState?.validate();
    if (error != null) {
      _showError(error);
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final emailError = FormValidators.email(_emailCtr.text);
    final passError = _passCtr.text.isEmpty ? 'Password is required' : null;
    final error = emailError ?? passError;
    setState(() => _bannerMessage = error);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (error != null || !formOk) {
      if (error != null) _showError(error);
      return;
    }

    setState(() {
      _busy = true;
      _bannerMessage = null;
    });
    final result = await _auth.login(_emailCtr.text.trim(), _passCtr.text);
    if (!mounted) return;
    if (result.isSuccess) {
      try {
        await _goHome();
      } catch (_) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => const AppShell()));
        }
      }
    } else {
      final msg = result.errorMessage ?? 'Login failed';
      if (isFirebaseConfigurationError(msg) && mounted) {
        showFirebaseSetupDialog(context, extraMessage: msg);
      }
      _showError(msg);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    final result = await _auth.signInWithGoogle();
    if (!mounted) return;
    if (result.isSuccess) {
      try {
        await _goHome();
      } catch (_) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => const AppShell()));
        }
      }
    } else {
      _showError(result.errorMessage);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _resetPassword() async {
    if (!_validateEmailOnly()) return;

    final email = _emailCtr.text.trim();
    setState(() => _busy = true);
    final error = await _auth.resetPassword(email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(error);
    }
  }

  @override
  void dispose() {
    _emailCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediBackground(
        child: AbsorbPointer(
          absorbing: _busy,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 36),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    shape: BoxShape.circle,
                    boxShadow: [AppTheme.softShadow(0.25)],
                  ),
                  child: const Icon(Icons.monitor_heart_rounded, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'MediVoice AI',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Medicine reminders · wellness · voice coach',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.inkMuted, fontSize: 15),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (_bannerMessage != null) ...[
                          const SizedBox(height: 12),
                          ValidationBanner(message: _bannerMessage!),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtr,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          enabled: !_busy,
                          onChanged: (_) {
                            if (_bannerMessage != null) {
                              setState(() => _bannerMessage = null);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                            hintText: 'you@gmail.com',
                          ),
                          validator: FormValidators.email,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtr,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          enabled: !_busy,
                          onFieldSubmitted: (_) {
                            if (!_busy) _login();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: _busy ? 'Signing in…' : 'Sign in',
                        icon: Icons.login_rounded,
                        busy: _busy,
                        onPressed: _busy ? null : _login,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _google,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('New here? Create an account'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
