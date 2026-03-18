import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../features/auth/auth_service.dart';

/// AdminDashboardScreen — shown only to users with role 'admin' in Firestore.
/// This is a placeholder screen for V1.
/// Full admin UI will be built in the UI phase.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current logged in user to display their email
    final user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepOrange,
        // Logout button in top right
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                // After logout go back to login screen
                Navigator.pushReplacementNamed(context, Routes.login);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Admin icon
            const Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: Colors.deepOrange,
            ),

            const SizedBox(height: 24),

            // Welcome message
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Show logged in admin email
            Text(
              'Logged in as: ${user?.email ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Placeholder text — full UI comes in design phase
            const Text(
              'Admin Panel — Full UI coming soon.',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}