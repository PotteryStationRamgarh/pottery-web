class ValidationUtils {
  ValidationUtils._();

  /// Validates email format using regex.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    
    return null;
  }

  /// Validates password strength.
  /// Minimum 8 characters, at least one uppercase, one lowercase, one number.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    
    return null;
  }
}
