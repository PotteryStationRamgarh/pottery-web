import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../auth_service.dart';

class VerifyPhoneController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  ConfirmationResult? _confirmationResult;
  Timer? _resendTimer;

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _codeSent = false;
  bool _alreadyVerified = false;
  int _resendSeconds = 0;
  String? _message;
  bool _isSuccess = false;

  bool get isSendingCode => _isSendingCode;
  bool get isVerifyingCode => _isVerifyingCode;
  bool get isBusy => _isSendingCode || _isVerifyingCode;
  bool get codeSent => _codeSent;
  bool get alreadyVerified => _alreadyVerified;
  int get resendSeconds => _resendSeconds;
  bool get canResend => _codeSent && _resendSeconds == 0 && !_isSendingCode;
  String? get message => _message;
  bool get isSuccess => _isSuccess;

  String get initialPhoneValue {
    final phone = _authService.currentPhoneNumber.trim();
    if (phone.startsWith('+91') && phone.length == 13) {
      return phone.substring(3);
    }
    return phone;
  }

  Future<bool> sendCode(
    String phoneNumber, {
    required bool consentAccepted,
  }) async {
    if (!consentAccepted) {
      _message =
          'Please accept the phone verification consent before continuing.';
      _isSuccess = false;
      notifyListeners();
      return false;
    }

    _isSendingCode = true;
    _alreadyVerified = false;
    _message = null;
    notifyListeners();

    try {
      final verifier = kIsWeb
          ? RecaptchaVerifier(
              auth: FirebaseAuthPlatform.instanceFor(
                app: Firebase.app(),
                pluginConstants: const <String, Object?>{},
              ),
              onError: (exception) {
                _message = _mapError(exception.code);
                _isSuccess = false;
                notifyListeners();
              },
              onExpired: () {
                _message =
                    'The verification session expired. Please request a new OTP.';
                _isSuccess = false;
                notifyListeners();
              },
            )
          : null;

      _confirmationResult = await _authService
          .startPhoneVerificationWithVerifier(phoneNumber, verifier: verifier);
      _codeSent = true;
      _isSuccess = true;
      _message = 'We sent a 6-digit OTP to your mobile number.';
      _startResendTimer();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'phone-already-verified') {
        _alreadyVerified = true;
        _isSuccess = true;
        _message = e.message ?? 'This phone number is already verified.';
        return true;
      }
      _isSuccess = false;
      _message = _mapError(e.code);
      return false;
    } catch (_) {
      _isSuccess = false;
      _message = 'Unable to send OTP right now. Please try again.';
      return false;
    } finally {
      _isSendingCode = false;
      notifyListeners();
    }
  }

  Future<bool> verifyCode(String code) async {
    if (_confirmationResult == null) {
      _message = 'Please request an OTP first.';
      _isSuccess = false;
      notifyListeners();
      return false;
    }

    _isVerifyingCode = true;
    _message = null;
    notifyListeners();

    try {
      await _authService.confirmPhoneVerification(_confirmationResult!, code);
      _isSuccess = true;
      _message = 'Phone verification completed successfully.';
      return true;
    } on FirebaseAuthException catch (e) {
      _isSuccess = false;
      _message = _mapError(e.code);
      return false;
    } catch (_) {
      _isSuccess = false;
      _message = 'The OTP could not be verified. Please try again.';
      return false;
    } finally {
      _isVerifyingCode = false;
      notifyListeners();
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendSeconds -= 1;
      if (_resendSeconds <= 0) {
        timer.cancel();
        _resendSeconds = 0;
      }
      notifyListeners();
    });
  }

  String _mapError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Enter a valid Indian mobile number.';
      case 'captcha-check-failed':
        return 'Phone verification was blocked by reCAPTCHA. Please refresh and try again.';
      case 'quota-exceeded':
        return 'SMS quota has been reached for now. Please try again later.';
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect.';
      case 'code-expired':
        return 'The OTP has expired. Please request a new code.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'provider-already-linked':
        return 'A verified phone number is already linked to this account.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'operation-not-allowed':
        return 'Phone verification is not enabled for this Firebase project yet.';
      case 'web-context-cancelled':
        return 'The verification popup was closed before completion. Please try again.';
      default:
        return 'Phone verification failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
