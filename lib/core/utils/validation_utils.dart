class ValidationUtils {
  ValidationUtils._();

  /// Validates email format using regex.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  /// Validates password strength.
  /// Minimum 8 characters, at least one uppercase, one lowercase,
  /// and one number.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    final hasMinLength = value.length >= 8;
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasNumber = value.contains(RegExp(r'[0-9]'));
    if (!hasMinLength || !hasUppercase || !hasLowercase || !hasNumber) {
      return 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number.';
    }

    return null;
  }
}
