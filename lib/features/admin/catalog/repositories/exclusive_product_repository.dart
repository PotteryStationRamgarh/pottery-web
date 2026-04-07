import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../models/product.dart';

/// ExclusiveProductRepository — single source of truth for exclusive product operations.
/// Handles all Firestore interactions and media uploads for exclusive products.
///
/// Rule: UI must NEVER import firestore_service directly.
/// All data flows through this repository.
class ExclusiveProductRepository {
  ExclusiveProductRepository._();

  static final _media = MediaService();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Get all exclusive products, sorted by order.
  static Future<List<ExclusiveProduct>> getExclusiveProducts({
    bool forceRefresh = false,
  }) async {
    try {
      return await FirestoreService.getExclusiveProducts(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('ExclusiveProductRepository.getExclusiveProducts error: $e');
      rethrow;
    }
  }

  /// Get single exclusive product by ID.
  static Future<ExclusiveProduct?> getExclusiveProduct(String id) async {
    try {
      final products = await FirestoreService.getExclusiveProducts();
      return products.where((p) => p.id == id).firstOrNull;
    } catch (e) {
      debugPrint('ExclusiveProductRepository.getExclusiveProduct error: $e');
      return null;
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  /// Add new exclusive product with multiple image uploads.
  static Future<String> addExclusiveProduct({
    required String title,
    required String description,
    required List<Uint8List> imageBytes,
    required int totalPieces,
    required bool hasCertificate,
    required String material,
    required String craftingTime,
    required int order,
    required bool isActive,
    required double mrp,
    required double sellingPrice,
    required int stockCount,
    required int weight,
    required List<String> careInstructions,
    required List<String> tags,
    required String seriesName,
    required String editionType,
    required String artistNote,
    String sku = '', // auto-generated if empty
  }) async {
    try {
      if (title.trim().isEmpty) {
        throw ArgumentError('Product title cannot be empty');
      }

      if (totalPieces <= 0) {
        throw ArgumentError('Total pieces must be greater than 0');
      }

      if (imageBytes.isEmpty) {
        throw ArgumentError('At least one image is required');
      }

      // 1. If order is 0 or less, auto-assign
      int finalOrder = order;
      if (finalOrder <= 0) {
        final existing = await getExclusiveProducts();
        finalOrder = existing.length + 1;
      }

      // 2. Handle SKU and auto-generated fields
      final finalSku = sku.isEmpty ? 'E-PSR-${DateTime.now().millisecondsSinceEpoch}' : sku;

      // 3. Create document with initial data
      final product = ExclusiveProduct(
        id: '', // Firestore will generate
        title: title.trim(),
        description: description.trim(),
        imageUrls: [], // Will update after upload
        totalPieces: totalPieces,
        hasCertificate: hasCertificate,
        material: material.trim(),
        craftingTime: craftingTime.trim(),
        order: finalOrder,
        isActive: isActive,
        mrp: mrp,
        sellingPrice: sellingPrice,
        stockCount: stockCount,
        isInStock: stockCount > 0,
        sku: finalSku,
        weight: weight,
        careInstructions: careInstructions,
        tags: tags,
        soldCount: 0,
        seriesName: seriesName,
        editionType: editionType,
        artistNote: artistNote,
      );

      final docRef = await FirestoreService.addExclusiveProduct(product);
      final docId = docRef.id;

      // 4. Upload images
      final urls = await _media.uploadImages(
        docId: docId,
        pathPrefix: 'exclusive_products',
        files: imageBytes,
      );

      // 5. Update with actual URLs
      if (urls.isNotEmpty) {
        await FirestoreService.updateExclusiveProduct(docId, {
          'imageUrls': urls,
        });
      }

      return docId;
    } catch (e) {
      debugPrint('ExclusiveProductRepository.addExclusiveProduct error: $e');
      rethrow;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  /// Update exclusive product (without images).
  /// Use updateExclusiveProductWithImages for image changes.
  static Future<void> updateExclusiveProduct({
    required String id,
    required String title,
    required String description,
    required int totalPieces,
    required bool hasCertificate,
    required String material,
    required String craftingTime,
    required int order,
    required bool isActive,
    required double mrp,
    required double sellingPrice,
    required int stockCount,
    required int weight,
    required List<String> careInstructions,
    required List<String> tags,
    required String seriesName,
    required String editionType,
    required String artistNote,
    required String sku,
  }) async {
    try {
      if (title.trim().isEmpty) {
        throw ArgumentError('Product title cannot be empty');
      }

      if (totalPieces <= 0) {
        throw ArgumentError('Total pieces must be greater than 0');
      }

      await FirestoreService.updateExclusiveProduct(id, {
        'title': title.trim(),
        'description': description.trim(),
        'totalPieces': totalPieces,
        'hasCertificate': hasCertificate,
        'material': material.trim(),
        'craftingTime': craftingTime.trim(),
        'order': order,
        'isActive': isActive,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
        'stockCount': stockCount,
        'isInStock': stockCount > 0,
        'weight': weight,
        'sku': sku,
        'careInstructions': careInstructions,
        'tags': tags,
        'seriesName': seriesName,
        'editionType': editionType,
        'artistNote': artistNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ExclusiveProductRepository.updateExclusiveProduct error: $e');
      rethrow;
    }
  }

  /// Update exclusive product with new images.
  static Future<void> updateExclusiveProductWithImages({
    required String id,
    required String title,
    required String description,
    required List<Uint8List> imageBytes,
    required int totalPieces,
    required bool hasCertificate,
    required String material,
    required String craftingTime,
    required int order,
    required bool isActive,
    required double mrp,
    required double sellingPrice,
    required int stockCount,
    required int weight,
    required List<String> careInstructions,
    required List<String> tags,
    required String seriesName,
    required String editionType,
    required String artistNote,
    required String sku,
  }) async {
    try {
      if (title.trim().isEmpty) {
        throw ArgumentError('Product title cannot be empty');
      }

      if (totalPieces <= 0) {
        throw ArgumentError('Total pieces must be greater than 0');
      }

      if (imageBytes.isEmpty) {
        throw ArgumentError('At least one image is required');
      }

      // 1. Upload new images
      final urls = await _media.uploadImages(
        docId: id,
        pathPrefix: 'exclusive_products',
        files: imageBytes,
      );

      // 2. Update document
      final updateData = {
        'title': title.trim(),
        'description': description.trim(),
        'totalPieces': totalPieces,
        'hasCertificate': hasCertificate,
        'material': material.trim(),
        'craftingTime': craftingTime.trim(),
        'order': order,
        'isActive': isActive,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
        'stockCount': stockCount,
        'isInStock': stockCount > 0,
        'weight': weight,
        'sku': sku,
        'careInstructions': careInstructions,
        'tags': tags,
        'seriesName': seriesName,
        'editionType': editionType,
        'artistNote': artistNote,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (urls.isNotEmpty) {
        updateData['imageUrls'] = urls;
      }

      await FirestoreService.updateExclusiveProduct(id, updateData);
    } catch (e) {
      debugPrint(
        'ExclusiveProductRepository.updateExclusiveProductWithImages error: $e',
      );
      rethrow;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  /// Delete exclusive product by ID.
  static Future<void> deleteExclusiveProduct(String id) async {
    try {
      if (id.isEmpty) {
        throw ArgumentError('Exclusive product ID cannot be empty');
      }

      await FirestoreService.deleteExclusiveProduct(id);
    } catch (e) {
      debugPrint('ExclusiveProductRepository.deleteExclusiveProduct error: $e');
      rethrow;
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  /// Check if product title is unique.
  static Future<bool> isProductTitleUnique(
    String title, {
    String? excludeId,
  }) async {
    try {
      final products = await FirestoreService.getExclusiveProducts();
      return !products.any(
        (p) =>
            p.title.toLowerCase() == title.toLowerCase() &&
            (excludeId == null || p.id != excludeId),
      );
    } catch (e) {
      debugPrint('ExclusiveProductRepository.isProductTitleUnique error: $e');
      return false;
    }
  }
}
