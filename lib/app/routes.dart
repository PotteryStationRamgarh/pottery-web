/// Central place for all named routes in the app.
/// Think of this as a directory — every screen has a unique address.
/// Always use these constants instead of hardcoding strings like '/signin'
/// because if you ever rename a route, you only change it in one place.
class Routes {
  // Private constructor — this class should never be instantiated
  // It only holds constants, no need to create an object of it
  Routes._();

  // ─────────────────────────────────────────
  // CORE
  // ─────────────────────────────────────────

  /// Very first screen on app launch
  /// Handles all routing logic — maintenance, auth, role check
  static const String splash = '/';

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  /// Login screen for existing users
  static const String signin = '/signin';

  /// Registration screen for new users
  static const String signup = '/signup';

  /// Shown after signup — user must verify email before they can enter
  static const String verifyEmail = '/verify-email';

  /// Password recovery screen
  static const String forgotPassword = '/forgot-password';

  // ─────────────────────────────────────────
  // MAINTENANCE
  // ─────────────────────────────────────────

  /// Shown to all non-admin users when maintenanceMode is true in Firestore
  /// Admin always bypasses this and goes directly to dashboard
  static const String maintenance = '/maintenance';

  // ─────────────────────────────────────────
  // CUSTOMER
  // ─────────────────────────────────────────

  /// Main home screen — hero, exclusive, exhibition, products, banner
  static const String customerHome = '/home';

  /// Category grid — browse products by category
  static const String categories = '/categories';

  /// Products list — filtered by selected category
  static const String products = '/products';

  /// Full detail page for a single exclusive product
  static const String exclusiveDetail = '/exclusive';

  // ─────────────────────────────────────────
  // ADMIN
  // ─────────────────────────────────────────

  /// Admin dashboard — only accessible to role: 'admin' users
  /// Manages app_config, products, categories, exclusive products
  static const String adminDashboard = '/admin';
}