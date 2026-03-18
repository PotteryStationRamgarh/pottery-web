import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../features/splash/splash_screen.dart'; // NOW ACTIVE

// import '../features/auth/login/login_screen.dart';
// import '../features/auth/signup/signup_screen.dart';
// import '../features/auth/verify_email/verify_email_screen.dart';
// import '../features/home/customer_home_screen.dart';
// import '../features/home/admin_dashboard_screen.dart';

/// Root widget of the application.
/// Defines theme, initial route, and all named routes.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pottery Station Ramgarh',

      // App starts at splash route
      initialRoute: Routes.splash,

      routes: {
        // SplashScreen is now active — handles all navigation logic
        Routes.splash: (context) => const SplashScreen(),

        // Uncommented one by one as we build each screen
        // Routes.login: (context) => const LoginScreen(),
        // Routes.signup: (context) => const SignupScreen(),
        // Routes.verifyEmail: (context) => const VerifyEmailScreen(),
        // Routes.customerHome: (context) => const CustomerHomeScreen(),
        // Routes.adminDashboard: (context) => const AdminDashboardScreen(),
      },
    );
  }
}