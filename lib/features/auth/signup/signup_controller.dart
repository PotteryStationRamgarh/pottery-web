import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/validation_utils.dart';
import '../auth_service.dart';

/// SignupController handles all business logic for the signup screen.
/// After successful signup it also creates a Firestore user document.
class SignupController {
  final AuthService _authService = AuthService();

  /// Attempts to create a new account with given credentials.
  ///
  /// Returns:
  /// - null → signup successful, verification email sent
  /// - any string → error message to show the user
  Future<String?> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Enhanced validation using ValidationUtils
    final emailError = ValidationUtils.validateEmail(email);
    if (emailError != null) return emailError;

    final passwordError = ValidationUtils.validatePassword(password);
    if (passwordError != null) return passwordError;

    // Check both passwords match before sending to Firebase
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    try {
      // Create account — auth_service also sends verification email automatically
      await _authService.signUp(email: email.trim(), password: password);

      // null = signup successful, verification email sent
      // Document creation is now moved to VerifyEmailController after success
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Maps Firebase error codes to user friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }
}
