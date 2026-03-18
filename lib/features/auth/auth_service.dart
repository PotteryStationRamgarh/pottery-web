import 'package:firebase_auth/firebase_auth.dart';

/// AuthService handles all Firebase Authentication operations.
/// This is the ONLY place in the app that directly talks to FirebaseAuth.
/// Controllers (login, signup) will call methods from this class.
class AuthService {
  
  // Single instance of FirebaseAuth — used across all methods
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream that emits a User object when logged in, null when logged out.
  /// Used by SplashScreen to reactively check auth state on app start.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently logged-in user, or null if no one is logged in.
  /// Useful for quick checks without listening to a stream.
  User? get currentUser => _auth.currentUser;

  /// Creates a new account with email and password.
  /// Automatically sends a verification email after account creation.
  /// Throws FirebaseAuthException if signup fails (caught in controller).
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    // Create the account in Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Immediately send verification email to the new user
    await credential.user?.sendEmailVerification();

    return credential;
  }

  /// Logs in an existing user with email and password.
  /// Throws FirebaseAuthException if login fails (caught in controller).
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Logs out the currently logged-in user.
  /// After this, authStateChanges stream will emit null.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Resends the verification email to the currently logged-in user.
  /// Called from the VerifyEmail screen if user didn't receive the email.
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Forces a refresh of the current user's data from Firebase servers.
  /// IMPORTANT: emailVerified status is cached locally — without reload(),
  /// it won't update even after the user verifies their email.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Returns true if the current user has verified their email.
  /// Always call reloadUser() before checking this, to get fresh status.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}