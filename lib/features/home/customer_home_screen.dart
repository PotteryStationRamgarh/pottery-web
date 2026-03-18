import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../features/auth/auth_service.dart';

/// CustomerHomeScreen — shown to verified customers after login.
/// This is a placeholder screen for V1.
/// Full UI and features will be built in the UI phase.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current logged in user to display their email
    final user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pottery Station Ramgarh'),
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

            // Welcome message
            const Text(
              'Welcome to Pottery Station Ramgarh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Show logged in user email
            Text(
              'Logged in as: ${user?.email ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Placeholder text — full UI comes in design phase
            const Text(
              'Customer Home — Full UI coming soon.',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}