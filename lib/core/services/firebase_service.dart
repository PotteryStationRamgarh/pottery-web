import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pottery_web/firebase_options.dart';

import 'system_email_service.dart';

/// FirebaseService handles global Firebase operations.
/// Role fetching lives here because it is a core utility
/// used by SplashScreen — not specific to any single feature.
class FirebaseService {
  // Private constructor — this class should never be instantiated
  FirebaseService._();

  // Single instance of Firestore — used across all methods
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initializes Firebase before the app starts.
  /// Called once in main.dart before runApp.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Fetches the role of a user from Firestore.
  ///
  /// Looks up the document at users/{uid} and reads the 'role' field.
  /// Returns 'customer' as default if:
  /// - Document does not exist
  /// - Role field is missing
  /// - Any error occurs
  ///
  /// Possible return values: 'admin' or 'customer'
  static Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      // Check if document exists and has data
      if (doc.exists && doc.data() != null) {
        // Read role field — default to customer if field is missing
        return doc.data()!['role'] ?? 'customer';
      }

      // No document found — treat as customer
      return 'customer';
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      // On any error — default to customer for safety
      return 'customer';
    }
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out failed: $e');
      rethrow;
    }
  }

  /// Creates a new user document in Firestore after signup.
  /// Called once after successful account creation.
  /// Default role is always 'customer' — admin is set manually in Firestore.
  static Future<void> createUserDocument({
    required String uid,
    required String email,
    String displayName = '',
  }) async {
    try {
      final docRef = _db.collection('users').doc(uid);
      final existing = await docRef.get();
      final isNewUser = !existing.exists;

      await docRef.set({
        'email': email,
        'displayName': displayName,
        'role':
            'customer', // Default role — change to admin manually in Firestore
        'phoneNumber': existing.data()?['phoneNumber'] ?? '',
        'phoneVerificationStatus':
            existing.data()?['phoneVerificationStatus'] ?? 'not_started',
        'createdAt':
            existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isNewUser) {
        await SystemEmailService.queueEmail(
          to: email,
          from: SystemEmailService.noReplyAddress,
          subject: 'Welcome to Pottery Station Ramgarh',
          body:
              'Your account is ready. You can browse freely and place orders once you sign in.',
          type: 'welcome',
          relatedEntityId: uid,
          relatedEntityType: 'user',
        );
      }
      debugPrint('User document created for $email');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data() ?? <String, dynamic>{};
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return <String, dynamic>{};
    }
  }

  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection('users').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}
