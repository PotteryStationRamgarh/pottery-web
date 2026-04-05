import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/validation_utils.dart';
import '../auth_service.dart';

class ForgotPasswordController {
  final AuthService _authService = AuthService();

  /// Sends a password reset email to the given address.
  ///
  /// Returns:
  /// - null → Email sent successfully
  /// - any string → error message to show the user
  Future<String?> sendResetEmail(String email) async {
    final emailError = ValidationUtils.validateEmail(email);
    if (emailError != null) return emailError;

    try {
      await _authService.sendPasswordResetEmail(email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }
}
