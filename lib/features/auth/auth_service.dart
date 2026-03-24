import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AuthService — the only class that talks directly to FirebaseAuth.
/// All controllers and screens call methods from here.
/// Never use FirebaseAuth directly anywhere else in the app.
class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // AUTH STATE
  // ─────────────────────────────────────────

  /// Stream — emits User when logged in, null when logged out.
  /// Used by SplashScreen to reactively check auth state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently logged in user — null if nobody logged in.
  User? get currentUser => _auth.currentUser;

  /// True if current user has verified their email.
  /// Always call reloadUser() first — emailVerified is cached locally.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ─────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────

  /// Creates a new account with email and password.
  /// Automatically sends verification email right after account creation.
  /// Throws FirebaseAuthException if it fails — caught in controller.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send verification email immediately after account is created
    // We use ActionCodeSettings to ensure the link is generated correctly
    // and can be handled by the app/browser properly.
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://pottery-station-ramgarh.web.app', // Update with real domain
      handleCodeInApp: true,
      iOSBundleId:     'com.potterystation.app',
      androidPackageName: 'com.potterystation.app',
      androidInstallApp: true,
      androidMinimumVersion: '1',
    );

    await credential.user?.sendEmailVerification(actionCodeSettings);

    return credential;
  }

  // ─────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────

  /// Signs in an existing user with email and password.
  /// Throws FirebaseAuthException if it fails — caught in controller.
  Future<UserCredential> signin({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────

  /// Signs out the current user.
  /// After this authStateChanges stream emits null.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────
  // EMAIL VERIFICATION
  // ─────────────────────────────────────────

  /// Resends the verification email to the currently logged in user.
  /// Called from VerifyEmailScreen when user taps resend button.
  Future<void> resendVerificationEmail() async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://pottery-station-ramgarh.web.app',
      handleCodeInApp: true,
      iOSBundleId:     'com.potterystation.app',
      androidPackageName: 'com.potterystation.app',
      androidInstallApp: true,
      androidMinimumVersion: '1',
    );
    await _auth.currentUser?.sendEmailVerification(actionCodeSettings);
  }

  /// Refreshes user data from Firebase servers.
  /// Must call this before checking isEmailVerified —
  /// the status is cached locally and won't update without this.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ─────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────

  /// Sends a password reset email to the given address.
  /// Firebase handles the reset link — user clicks it to set new password.
  /// Throws FirebaseAuthException if email is not registered.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─────────────────────────────────────────
  // USER ROLE
  // ─────────────────────────────────────────

  /// Fetches the role of the current user from Firestore users/{uid}.
  /// Returns 'customer' by default if:
  /// - No user is logged in
  /// - Document does not exist
  /// - Role field is missing
  /// - Any error occurs
  ///
  /// Possible values: 'admin' or 'customer'
  Future<String> getUserRole() async {
    try {
      final uid = _auth.currentUser?.uid;

      // No user logged in — default to customer
      if (uid == null) return 'customer';

      final doc = await _db.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String? ?? 'customer';
      }

      // Document not found — default to customer
      return 'customer';
    } catch (e) {
      // Any error — default to customer for safety
      return 'customer';
    }
  }
}