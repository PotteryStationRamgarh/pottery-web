import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../auth_service.dart';

/// VerifyEmailController — all business logic for the verify email screen.
/// The screen and form widgets call methods from here — zero logic in UI files.
///
/// Handles:
/// - Auto checking every 5 seconds if email is verified
/// - Re-checking immediately when app resumes (iPhone fix)
/// - 30 second resend cooldown with live countdown
/// - Manual "I've verified" check
/// - Role-based navigation after verification
class VerifyEmailController extends ChangeNotifier {

  final AuthService _authService = AuthService();

  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  // Timers
  Timer? _checkTimer;
  Timer? _cooldownTimer;

  // Resend cooldown
  bool _resendCooldown   = false;
  int  _cooldownSeconds  = 0;

  // Feedback message shown to user
  String? _message;
  bool    _isSuccess  = false;

  // Loading state for manual check button
  bool _isChecking = false;

  // ─────────────────────────────────────────
  // GETTERS — read by the form widget
  // ─────────────────────────────────────────

  bool    get resendCooldown  => _resendCooldown;
  int     get cooldownSeconds => _cooldownSeconds;
  String? get message         => _message;
  bool    get isSuccess       => _isSuccess;
  bool    get isChecking      => _isChecking;

  // Masked email shown for privacy — he****@gmail.com
  String get maskedEmail {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name   = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name****@$domain';
    return '${name.substring(0, 2)}****@$domain';
  }

  // ─────────────────────────────────────────
  // INIT — call from screen initState
  // ─────────────────────────────────────────

  /// Starts the auto-check timer.
  /// Call this from the screen's initState.
  void init() {
    _startAutoCheck();
  }

  // ─────────────────────────────────────────
  // AUTO CHECK — every 5 seconds
  // ─────────────────────────────────────────

  void _startAutoCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _authService.reloadUser();
      if (_authService.isEmailVerified) {
        _checkTimer?.cancel();
        _cooldownTimer?.cancel();
        
        // Create user document only after verification is confirmed
        await _ensureUserDocumentCreated();
        
        notifyListeners();
      }
    });
  }

  /// Ensures Firestore user document exists.
  /// Called only after email verification is confirmed.
  Future<void> _ensureUserDocumentCreated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseService.createUserDocument(
        uid: user.uid,
        email: user.email!,
      );
    }
  }

  // ─────────────────────────────────────────
  // VERIFICATION CHECK
  // Called by auto-check, app resume, and manual button
  // Returns the role string if verified, null if not verified yet
  // ─────────────────────────────────────────

  Future<String?> checkVerification() async {
    await _authService.reloadUser();

    if (_authService.isEmailVerified) {
      _checkTimer?.cancel();
      _cooldownTimer?.cancel();
      
      // Ensure document is created before navigating
      await _ensureUserDocumentCreated();
      
      // Return role so screen can navigate accordingly
      return await _authService.getUserRole();
    }

    return null;
  }

  // ─────────────────────────────────────────
  // MANUAL CHECK — "I've Verified" button
  // ─────────────────────────────────────────

  /// Returns role string if verified, null if not yet verified.
  /// Screen uses the return value to navigate.
  Future<String?> handleManualCheck() async {
    _isChecking = true;
    notifyListeners();

    final role = await checkVerification();

    if (role == null) {
      // Not verified yet — show error message
      _isChecking = false;
      _message    = 'Email not verified yet. Please click the link in your email first.';
      _isSuccess  = false;
      notifyListeners();
    }

    // If verified role is returned — screen handles navigation
    // isChecking stays true so button stays disabled during navigation
    return role;
  }

  // ─────────────────────────────────────────
  // APP RESUME — iPhone fix
  // Call this from didChangeAppLifecycleState
  // ─────────────────────────────────────────

  /// Returns role string if verified, null if not yet verified.
  /// Called when app comes back from background (Safari on iPhone).
  Future<String?> handleAppResume() async {
    return await checkVerification();
  }

  // ─────────────────────────────────────────
  // RESEND WITH COUNTDOWN
  // ─────────────────────────────────────────

  Future<void> handleResend() async {
    try {
      await _authService.resendVerificationEmail();

      _message         = 'Verification email sent. Check your inbox.';
      _isSuccess       = true;
      _resendCooldown  = true;
      _cooldownSeconds = 30;
      notifyListeners();

      // Tick down every second — user sees live countdown on button
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _resendCooldown = false;
          t.cancel();
        }
        notifyListeners(); // Force UI to update
      });

    } catch (_) {
      _message   = 'Failed to resend. Please try again.';
      _isSuccess = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────

  Future<void> handleLogout() async {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    await _authService.logout();
  }

  // ─────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
}