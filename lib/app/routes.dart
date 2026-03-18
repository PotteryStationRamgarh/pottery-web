/// Central place for all named routes in the app.
/// Always use these constants instead of hardcoding strings like '/signin'.
/// This prevents typos and makes refactoring easy.
class Routes {
  
  // Private constructor — this class should never be instantiated
  Routes._();

  /// First screen shown when app launches
  static const String splash = '/';

  /// Signin screen for existing users
  static const String signin = '/signin';

  /// Signup screen for new users
  static const String signup = '/signup';

  /// Shown after signup — user must verify email before proceeding
  static const String verifyEmail = '/verify-email';

  /// Home screen for customers
  static const String customerHome = '/home';

  /// Dashboard screen for admins
  static const String adminDashboard = '/admin';
}