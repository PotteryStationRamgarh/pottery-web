import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../login/login_controller.dart';

/// LoginScreen — UI for existing users to sign in.
/// Kept simple for now — proper design comes in UI phase.
/// This screen only handles layout and user input.
/// All logic is delegated to LoginController.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller that holds all login business logic
  final LoginController _controller = LoginController();

  // Text controllers to read user input from fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Tracks whether a login request is in progress
  bool _isLoading = false;

  // Holds error message to display under the form, null means no error
  String? _errorMessage;

  /// Called when user taps Login button.
  /// Delegates to controller and handles the result.
  Future<void> _handleLogin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Show loading spinner
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Call controller login method
    final result = await _controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Safety check after async gap
    if (!mounted) return;

    // Hide loading spinner
    setState(() => _isLoading = false);

    if (result == null) {
      // null means success — go to customer home
      Navigator.pushReplacementNamed(context, Routes.customerHome);
    } else if (result == 'email_not_verified') {
      // Special case — user exists but email not verified
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
    } else {
      // Any other string is an error message — show it
      setState(() => _errorMessage = result);
    }
  }

  @override
  void dispose() {
    // Always dispose text controllers to free memory
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          // Fixed width so it looks decent on web without full design
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Pottery Station Ramgarh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),

                // Error message — only visible when _errorMessage is not null
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 16),

                // Login button — shows spinner when loading
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),

                const SizedBox(height: 16),

                // Navigate to signup
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.signup);
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}