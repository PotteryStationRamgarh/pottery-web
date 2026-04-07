import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../models/product_category.dart';

/// CategoryRepository — single source of truth for product category operations.
/// Handles all Firestore interactions and media uploads for categories.
///
/// Rule: UI must NEVER import firestore_service directly.
/// All data flows through this repository.
class CategoryRepository {
  CategoryRepository._();

  static final _media = MediaService();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Get all categories, sorted by order.
  static Future<List<ProductCategory>> getCategories({
    bool forceRefresh = false,
  }) async {
    try {
      return await FirestoreService.getCategories(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('CategoryRepository.getCategories error: $e');
      rethrow;
    }
  }

  /// Get a single category by ID.
  static Future<ProductCategory?> getCategory(String id) async {
    try {
      final categories = await FirestoreService.getCategories();
      return categories.where((c) => c.id == id).firstOrNull;
    } catch (e) {
      debugPrint('CategoryRepository.getCategory error: $e');
      return null;
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  /// Add new category with single image upload.
  static Future<String> addCategory({
    required String name,
    required String description,
    required Uint8List imageBytes,
    required int order,
    required bool isActive,
  }) async {
    try {
      if (name.trim().isEmpty) {
        throw ArgumentError('Category name cannot be empty');
      }

      // 1. If order is 0 or less, auto-assign
      int finalOrder = order;
      if (finalOrder <= 0) {
        final existing = await getCategories();
        finalOrder = existing.length + 1;
      }

      // 2. Create document with empty imageUrl first
      final category = ProductCategory(
        id: '', // Firestore will generate
        name: name.trim(),
        description: description.trim(),
        imageUrl: '', // Will update after upload
        order: finalOrder,
        isActive: isActive,
      );

      final docRef = await FirestoreService.addCategory(category);
      final docId = docRef.id;

      // 2. Upload image
      final urls = await _media.uploadImages(
        docId: docId,
        pathPrefix: 'categories',
        files: [imageBytes],
      );

      // 3. Update with actual URL
      if (urls.isNotEmpty) {
        await FirestoreService.updateCategory(docId, {'imageUrl': urls.first});
      }

      return docId;
    } catch (e) {
      debugPrint('CategoryRepository.addCategory error: $e');
      rethrow;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  /// Update category (without image). Use updateCategoryWithImage for image changes.
  static Future<void> updateCategory({
    required String id,
    required String name,
    required String description,
    required int order,
    required bool isActive,
  }) async {
    try {
      if (name.trim().isEmpty) {
        throw ArgumentError('Category name cannot be empty');
      }

      await FirestoreService.updateCategory(id, {
        'name': name.trim(),
        'description': description.trim(),
        'order': order,
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('CategoryRepository.updateCategory error: $e');
      rethrow;
    }
  }

  /// Update category with new image.
  static Future<void> updateCategoryWithImage({
    required String id,
    required String name,
    required String description,
    required Uint8List imageBytes,
    required int order,
    required bool isActive,
  }) async {
    try {
      if (name.trim().isEmpty) {
        throw ArgumentError('Category name cannot be empty');
      }

      // 1. Upload new image
      final urls = await _media.uploadImages(
        docId: id,
        pathPrefix: 'categories',
        files: [imageBytes],
      );

      // 2. Update document
      final updateData = {
        'name': name.trim(),
        'description': description.trim(),
        'order': order,
        'isActive': isActive,
      };

      if (urls.isNotEmpty) {
        updateData['imageUrl'] = urls.first;
      }

      await FirestoreService.updateCategory(id, updateData);
    } catch (e) {
      debugPrint('CategoryRepository.updateCategoryWithImage error: $e');
      rethrow;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  /// Delete category.
  /// WARNING: Does not check for dependent products.
  static Future<void> deleteCategory(String id) async {
    try {
      if (id.isEmpty) {
        throw ArgumentError('Category ID cannot be empty');
      }

      await FirestoreService.deleteCategory(id);
    } catch (e) {
      debugPrint('CategoryRepository.deleteCategory error: $e');
      rethrow;
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  /// Check if category name is unique (for validation).
  static Future<bool> isCategoryNameUnique(
    String name, {
    String? excludeId,
  }) async {
    try {
      final categories = await FirestoreService.getCategories();
      return !categories.any(
        (c) =>
            c.name.toLowerCase() == name.toLowerCase() &&
            (excludeId == null || c.id != excludeId),
      );
    } catch (e) {
      debugPrint('CategoryRepository.isCategoryNameUnique error: $e');
      return false;
    }
  }
}
