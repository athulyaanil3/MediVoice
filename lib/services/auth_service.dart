import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/form_validators.dart';

class AuthResult {
  const AuthResult({this.user, this.errorMessage});
  final User? user;
  final String? errorMessage;
  bool get isSuccess => user != null;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuthResult> register({
    required String email,
    required String password,
    String? username,
  }) async {
    final emailError = FormValidators.email(email);
    if (emailError != null) return AuthResult(errorMessage: emailError);
    final passwordError = FormValidators.password(password);
    if (passwordError != null) return AuthResult(errorMessage: passwordError);

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) return const AuthResult(errorMessage: 'Account created but user is null.');

      final displayName = username?.trim().isNotEmpty == true
          ? username!.trim()
          : email.split('@').first;

      try {
        await _firestore.collection('users').doc(user.uid).set({
          'username': displayName,
          'email': email.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Auth succeeded; profile write can fail if rules block it — still allow login.
        return AuthResult(
          user: user,
          errorMessage: 'Account created. Firestore profile pending: $e',
        );
      }

      return AuthResult(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(errorMessage: _firebaseMessage(e));
    } catch (e) {
      return AuthResult(errorMessage: 'Registration error: $e');
    }
  }

  Future<AuthResult> login(String email, String password) async {
    final emailError = FormValidators.email(email);
    if (emailError != null) return AuthResult(errorMessage: emailError);
    if (password.isEmpty) return const AuthResult(errorMessage: 'Password is required');

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(user: result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(errorMessage: _firebaseMessage(e));
    } catch (e) {
      return AuthResult(errorMessage: 'Login error: $e');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': user.displayName ?? user.email?.split('@').first ?? 'User',
          'email': user.email ?? '',
          'createdAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      return AuthResult(user: user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return const AuthResult();
      return AuthResult(errorMessage: 'Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      return AuthResult(errorMessage: _firebaseMessage(e));
    } catch (e) {
      return AuthResult(errorMessage: 'Google sign-in error: $e');
    }
  }

  Future<String?> resetPassword(String email) async {
    final emailError = FormValidators.email(email);
    if (emailError != null) return emailError;

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _firebaseMessage(e);
    } catch (e) {
      return 'Reset error: $e';
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Waits for Firebase to restore a saved session on this device.
  Future<User?> waitForSignedInUser() async {
    try {
      return await _auth.authStateChanges().first.timeout(
            const Duration(seconds: 5),
          );
    } catch (_) {
      return _auth.currentUser;
    }
  }

  static bool _isConfigurationMissing(FirebaseAuthException e) {
    final msg = '${e.message ?? ''} ${e.code}'.toUpperCase();
    return e.code == 'internal-error' ||
        e.code == 'configuration-not-found' ||
        msg.contains('CONFIGURATION_NOT_FOUND');
  }

  static String _firebaseMessage(FirebaseAuthException e) {
    if (_isConfigurationMissing(e)) {
      return 'Firebase Auth not configured. Enable Email/Password in Firebase Console → Authentication → Sign-in method.';
    }
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Use Sign in instead.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Wrong email or password.';
      case 'user-not-found':
        return 'No account for this email. Create an account first.';
      case 'operation-not-allowed':
        return 'Email sign-in is disabled in Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Auth failed (${e.code})';
    }
  }
}
