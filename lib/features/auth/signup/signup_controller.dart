import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';

/// SignupController handles all business logic for the signup screen.
/// SignupScreen calls this — SignupScreen itself has zero logic.
class SignupController {

  // AuthService is the only class that talks to Firebase directly
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

    // Basic empty field validation before hitting Firebase
    if (email.trim().isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return 'All fields are required.';
    }

    // Check both passwords match before sending to Firebase
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    // Firebase minimum is 6 but we check here for better UX
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    try {
      // Create account — auth_service also sends verification email automatically
      await _authService.signUp(
        email: email.trim(),
        password: password,
      );

      // null = signup successful, verification email sent
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