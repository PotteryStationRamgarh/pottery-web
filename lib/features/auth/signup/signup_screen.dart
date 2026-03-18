import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../signup/signup_controller.dart';

/// SignupScreen — UI for new users to create an account.
/// All logic is delegated to SignupController.
/// After successful signup user is sent to VerifyEmail screen.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  // Controller that holds all signup business logic
  final SignupController _controller = SignupController();

  // Text controllers to read user input from fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Tracks whether a signup request is in progress
  bool _isLoading = false;

  // Holds error message to display under form, null means no error
  String? _errorMessage;

  /// Called when user taps Sign Up button.
  /// Delegates to controller and handles result.
  Future<void> _handleSignup() async {

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Show loading spinner
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Call controller signup method
    final result = await _controller.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    // Safety check after async gap
    if (!mounted) return;

    // Hide loading spinner
    setState(() => _isLoading = false);

    if (result == null) {
      // null means success — go to verify email screen
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
    } else {
      // Any string is an error message — show it
      setState(() => _errorMessage = result);
    }
  }

  @override
  void dispose() {
    // Always dispose text controllers to free memory
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  'Create a new account',
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

                const SizedBox(height: 16),

                // Confirm password field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
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

                // Signup button — shows spinner when loading
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign Up'),
                ),

                const SizedBox(height: 16),

                // Navigate back to login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, Routes.login);
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}