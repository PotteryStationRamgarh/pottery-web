import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// BrandingService fetches branding images from Firestore.
/// These images were uploaded to Cloudinary by admin and their
/// URLs are stored in Firestore under settings/branding collection.
///
/// If multiple images exist — a random one is selected each time.
/// If no images exist — UI shows grey placeholder box with ? icon.
class BrandingService {
  // Private constructor — never instantiate this class
  BrandingService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches all branding image URLs from Firestore.
  /// Returns a list of URL strings.
  /// Returns empty list if none exist or on error.
  static Future<List<String>> getBrandingImageUrls() async {
    try {
      final doc = await _db.collection('settings').doc('branding').get();

      if (!doc.exists || doc.data() == null) {
        return [];
      }

      final data = doc.data()!;
      final List<String> urls = [];

      // Collect all keys starting with imageUrl
      data.forEach((key, value) {
        if (key.startsWith('imageUrl') && value is String && value.isNotEmpty) {
          urls.add(value);
        }
      });

      return urls;
    } catch (e) {
      debugPrint('Error fetching branding images: $e');
      return [];
    }
  }

  /// Saves a new branding image URL to Firestore.
  /// Uses merge so existing images are not overwritten.
  static Future<void> addBrandingImageUrl(String imageUrl) async {
    try {
      final urls = await getBrandingImageUrls();
      final int index = urls.length;

      await _db.collection('settings').doc('branding').set({
        'imageUrl_$index': imageUrl,
      }, SetOptions(merge: true));

      debugPrint('Branding image saved at index $index: $imageUrl');
    } catch (e) {
      debugPrint('Error saving branding image URL: $e');
      rethrow;
    }
  }

  /// Deletes all branding images from Firestore.
  static Future<void> clearBrandingImages() async {
    try {
      await _db.collection('settings').doc('branding').delete();
      debugPrint('All branding images cleared');
    } catch (e) {
      debugPrint('Error clearing branding images: $e');
      rethrow;
    }
  }
}
