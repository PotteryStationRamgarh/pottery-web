import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/validation_utils.dart';
import '../auth_service.dart';

/// SigninController handles all business logic for the signin screen.
/// SigninScreen calls this — SigninScreen itself has zero logic.
class SigninController {
  // AuthService is the only class that talks to Firebase directly
  final AuthService _authService = AuthService();

  /// Attempts to log in the user with given credentials.
  ///
  /// Returns:
  /// - null → Signin successful and email is verified
  /// - 'email_not_verified' → Signin worked but email not verified yet
  /// - any other string → error message to show the user
  Future<String?> signin({
    required String email,
    required String password,
  }) async {
    // Enhanced validation using ValidationUtils
    final emailError = ValidationUtils.validateEmail(email);
    if (emailError != null) return emailError;

    if (password.trim().isEmpty) {
      return 'Password is required.';
    }

    try {
      // Attempt Firebase signin
      final credential = await _authService.signin(
        email: email.trim(),
        password: password,
      );

      // Sign-in already returns the latest user payload, so we can avoid
      // an extra round-trip here and only fall back to verify flow when needed.
      if (!(credential.user?.emailVerified ?? false)) {
        // Return sentinel value — signinScreen handles this separately
        return 'email_not_verified';
      }

      // null = everything passed, signin successful
      return null;
    } on FirebaseAuthException catch (e) {
      // Convert Firebase error codes to readable messages
      return _mapFirebaseError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Signin failed. Please try again.';
    }
  }
}
