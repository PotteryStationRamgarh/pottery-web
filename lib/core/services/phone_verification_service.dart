import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// Firebase Phone Authentication Service — Flutter Web + Real Production Numbers
///
/// Uses firebase_auth's built-in RecaptchaVerifier (no raw JS access needed).
/// Call [sendOTP] first, then [verifyOTP] with the code the user enters.
///
/// Flow:
///   1. [sendOTP('+91XXXXXXXXXX')] → reCAPTCHA runs invisibly → OTP sent
///   2. [verifyOTP('123456')]      → links phone to current signed-in user
///
/// NOTE: This does NOT sign out + re-sign-in. It uses linkWithPhoneNumber /
/// linkWithCredential so the existing Google/email session is preserved.
class PhoneVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ──────────────────────────────────────────────────────────────────
  static RecaptchaVerifier? _recaptchaVerifier;
  static ConfirmationResult? _confirmationResult; // web-only
  static String _verificationId = '';            // mobile-only
  static DateTime? _lockoutUntil;
  static int _verificationAttempts = 0;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Send OTP to a phone number.
  ///
  /// [phoneNumber] must be in `+91XXXXXXXXXX` format.
  /// Returns the verificationId string (non-null on success).
  static Future<String?> sendOTP(String phoneNumber) async {
    try {
      if (isLockedOut()) {
        final mins = getLockoutMinutesRemaining();
        throw Exception('Too many attempts. Try again in $mins minutes.');
      }

      if (!_isValidIndianPhone(phoneNumber)) {
        throw Exception('Invalid phone number. Use +91 followed by 10 digits.');
      }

      debugPrint('PhoneAuth: Sending OTP to $phoneNumber…');

      if (kIsWeb) {
        await _sendOTPWeb(phoneNumber);
      } else {
        await _sendOTPMobile(phoneNumber);
      }

      _verificationAttempts = 0;
      debugPrint('PhoneAuth: OTP sent ✓');
      return _verificationId;
    } catch (e) {
      _verificationAttempts++;
      if (e.toString().contains('too-many-requests')) {
        _lockoutUntil = DateTime.now().add(const Duration(hours: 24));
      }
      debugPrint('PhoneAuth ERROR: sendOTP — $e');
      rethrow;
    }
  }

  /// Verify the OTP code entered by the user.
  ///
  /// Links the verified phone number to the currently signed-in user.
  /// Returns [UserCredential] on success (may be null if already linked).
  static Future<UserCredential?> verifyOTP(String otpCode) async {
    try {
      if (otpCode.isEmpty || otpCode.length != 6) {
        throw Exception('OTP must be exactly 6 digits.');
      }

      debugPrint('PhoneAuth: Verifying OTP…');

      if (kIsWeb) {
        return await _verifyOTPWeb(otpCode);
      } else {
        return await _verifyOTPMobile(otpCode);
      }
    } catch (e) {
      debugPrint('PhoneAuth ERROR: verifyOTP — $e');
      rethrow;
    }
  }

  /// Call after a successful or cancelled verification to free resources.
  static void resetState() {
    _confirmationResult = null;
    _verificationId = '';
    // Don't clear the RecaptchaVerifier — it can be reused within the same page.
    debugPrint('PhoneAuth: State reset');
  }

  /// Call on user logout to fully clean up the RecaptchaVerifier.
  static void clearRecaptcha() {
    try {
      _recaptchaVerifier?.clear();
    } catch (_) {}
    _recaptchaVerifier = null;
    debugPrint('PhoneAuth: RecaptchaVerifier cleared');
  }

  static bool isLockedOut() {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      return false;
    }
    return true;
  }

  static int getLockoutMinutesRemaining() {
    if (_lockoutUntil == null) return 0;
    return (_lockoutUntil!.difference(DateTime.now()).inSeconds / 60).ceil();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB IMPLEMENTATION (uses ConfirmationResult)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _sendOTPWeb(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user. Please sign in first.',
      );
    }

    // Always create a fresh verifier — reusing after failure causes errors
    _recaptchaVerifier?.clear();
    _recaptchaVerifier = RecaptchaVerifier(
      // Pass FirebaseAuthPlatform (not FirebaseAuth) using instanceFor
      auth: FirebaseAuthPlatform.instanceFor(
        app: _auth.app,
        pluginConstants: {},
      ),
      // No container → invisible reCAPTCHA overlay (recommended for web)
      size: RecaptchaVerifierSize.normal,
      theme: RecaptchaVerifierTheme.light,
      onSuccess: () => debugPrint('PhoneAuth: reCAPTCHA success'),
      onError: (FirebaseAuthException e) =>
          debugPrint('PhoneAuth: reCAPTCHA error — ${e.code}'),
      onExpired: () => debugPrint('PhoneAuth: reCAPTCHA expired'),
    );

    try {
      // linkWithPhoneNumber adds phone to the current user WITHOUT signing out.
      _confirmationResult = await user.linkWithPhoneNumber(
        phoneNumber,
        _recaptchaVerifier!,
      );
      _verificationId = 'web_pending';
    } on FirebaseAuthException catch (e) {
      // 'provider-already-linked' means this phone is already attached.
      // Treat as success so the user can proceed.
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        debugPrint('PhoneAuth: Phone already linked — skipping OTP');
        _verificationId = 'already_linked';
        return;
      }
      // Other errors: reset verifier so it gets recreated next time.
      _recaptchaVerifier?.clear();
      _recaptchaVerifier = null;
      rethrow;
    } catch (e) {
      _recaptchaVerifier?.clear();
      _recaptchaVerifier = null;
      rethrow;
    }
  }

  static Future<UserCredential?> _verifyOTPWeb(String otpCode) async {
    // Already-linked path: nothing further to confirm.
    if (_verificationId == 'already_linked') {
      resetState();
      return null;
    }

    if (_confirmationResult == null) {
      throw Exception('No pending verification. Please send OTP first.');
    }

    try {
      final cred = await _confirmationResult!.confirm(otpCode);
      debugPrint('PhoneAuth: OTP confirmed ✓');
      resetState();
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked') {
        debugPrint('PhoneAuth: Phone already linked — treating as success');
        resetState();
        return null;
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE IMPLEMENTATION (uses PhoneAuthCredential + linkWithCredential)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _sendOTPMobile(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verify (Android only): silently link the phone.
        final user = _auth.currentUser;
        if (user == null) return;
        try {
          await user.linkWithCredential(credential);
          debugPrint('PhoneAuth: Auto-verification linked ✓');
        } on FirebaseAuthException catch (e) {
          if (e.code != 'provider-already-linked' &&
              e.code != 'credential-already-in-use') {
            debugPrint('PhoneAuth ERROR: Auto-link — ${e.code}');
          }
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        debugPrint('PhoneAuth: Code sent, verificationId stored');
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('PhoneAuth ERROR: verificationFailed — ${e.code}: ${e.message}');
        // ignore: only_throw_errors
        throw e;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        debugPrint('PhoneAuth: Auto-retrieval timeout');
      },
    );
  }

  static Future<UserCredential?> _verifyOTPMobile(String otpCode) async {
    if (_verificationId.isEmpty) {
      throw Exception('No pending verification. Please send OTP first.');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user. Cannot verify phone.',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: otpCode,
    );
    try {
      final userCred = await user.linkWithCredential(credential);
      debugPrint('PhoneAuth: Credential linked ✓');
      resetState();
      return userCred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        debugPrint('PhoneAuth: Already linked — treating as success');
        resetState();
        return null;
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static bool _isValidIndianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(\+91|91)?[6-9]\d{9}$').hasMatch(cleaned);
  }
}
