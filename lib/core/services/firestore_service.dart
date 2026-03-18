import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// FirestoreService handles all Firestore database operations.
/// This is the ONLY place in the app that directly talks to Firestore
/// for content related data (images, portfolio, settings).
///
/// Structure in Firestore:
/// settings/branding → { loginImage: "url", signupImage: "url" }
/// portfolio/        → collection of portfolio items with image URLs
class FirestoreService {
  // Private constructor — this class should never be instantiated
  FirestoreService._();

  // Single instance of Firestore
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // BRANDING SECTION
  // Stores URLs for login and signup page images
  // ─────────────────────────────────────────

  /// Saves the login page image URL to Firestore.
  /// Called by admin after uploading image to Cloudinary.
  static Future<void> setLoginImage(String imageUrl) async {
    try {
      await _db.collection('settings').doc('branding').set(
        {'loginImage': imageUrl},
        SetOptions(merge: true), // merge so other fields are not overwritten
      );
      debugPrint('Login image URL saved: $imageUrl');
    } catch (e) {
      debugPrint('Error saving login image URL: $e');
      rethrow;
    }
  }

  /// Saves the signup page image URL to Firestore.
  /// Called by admin after uploading image to Cloudinary.
  static Future<void> setSignupImage(String imageUrl) async {
    try {
      await _db.collection('settings').doc('branding').set(
        {'signupImage': imageUrl},
        SetOptions(merge: true), // merge so other fields are not overwritten
      );
      debugPrint('Signup image URL saved: $imageUrl');
    } catch (e) {
      debugPrint('Error saving signup image URL: $e');
      rethrow;
    }
  }

  /// Fetches branding settings from Firestore.
  /// Returns a map with loginImage and signupImage URLs.
  /// Returns empty map if no branding document exists yet.
  static Future<Map<String, dynamic>> getBrandingSettings() async {
    try {
      final doc = await _db.collection('settings').doc('branding').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      // No branding document yet — return empty map
      return {};
    } catch (e) {
      debugPrint('Error fetching branding settings: $e');
      return {};
    }
  }

  // ─────────────────────────────────────────
  // PORTFOLIO SECTION
  // Stores portfolio items with image URLs
  // ─────────────────────────────────────────

  /// Adds a new portfolio item to Firestore.
  /// [imageUrl] — Cloudinary URL of the portfolio image
  /// [title] — title of the portfolio item
  /// [description] — optional description
  static Future<void> addPortfolioItem({
    required String imageUrl,
    required String title,
    String description = '',
  }) async {
    try {
      await _db.collection('portfolio').add({
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Portfolio item added: $title');
    } catch (e) {
      debugPrint('Error adding portfolio item: $e');
      rethrow;
    }
  }

  /// Fetches all portfolio items from Firestore.
  /// Returns a list of maps with image URLs and titles.
  /// Returns empty list if no items exist yet.
  static Future<List<Map<String, dynamic>>> getPortfolioItems() async {
    try {
      final snapshot = await _db
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .get();

      // Convert each document to a map and include document ID
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching portfolio items: $e');
      return [];
    }
  }

  /// Deletes a portfolio item from Firestore by document ID.
  /// Called by admin from the admin dashboard.
  static Future<void> deletePortfolioItem(String docId) async {
    try {
      await _db.collection('portfolio').doc(docId).delete();
      debugPrint('Portfolio item deleted: $docId');
    } catch (e) {
      debugPrint('Error deleting portfolio item: $e');
      rethrow;
    }
  }
}