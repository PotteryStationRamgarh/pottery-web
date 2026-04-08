import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../models/product.dart';

/// ProductRepository — single source of truth for product operations.
/// Handles all Firestore interactions and media uploads for products.
///
/// Rule: UI must NEVER import firestore_service directly.
/// All data flows through this repository.
class ProductRepository {
  ProductRepository._();

  static final _media = MediaService();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Get all products, sorted by order.
  static Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    try {
      return await FirestoreService.getAllProducts(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('ProductRepository.getProducts error: $e');
      rethrow;
    }
  }

  /// Get products by category ID.
  static Future<List<Product>> getProductsByCategory(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (categoryId.isEmpty) {
        throw ArgumentError('Category ID cannot be empty');
      }

      return await FirestoreService.getProductsByCategory(
        categoryId,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('ProductRepository.getProductsByCategory error: $e');
      rethrow;
    }
  }

  /// Get single product by ID.
  static Future<Product?> getProduct(String id) async {
    try {
      final products = await FirestoreService.getAllProducts();
      return products.where((p) => p.id == id).firstOrNull;
    } catch (e) {
      debugPrint('ProductRepository.getProduct error: $e');
      return null;
    }
  }

  /// Get all categories (used in product form).
  static Future<List<ProductCategory>> getCategories({
    bool forceRefresh = false,
  }) async {
    try {
      return await FirestoreService.getCategories(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('ProductRepository.getCategories error: $e');
      rethrow;
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  /// Add new product with multiple image uploads.
  static Future<String> addProduct({
    required String title,
    required String description,
    required String categoryId,
    required List<Uint8List> imageBytes,
    required int order,
    required bool isActive,
    required double mrp,
    required double sellingPrice,
    required int stockCount,
    required int weight,
    required String material,
    required Map<String, dynamic> dimensions,
    required List<String> careInstructions,
    required List<String> tags,
    String sku = '', // auto-generated if empty
  }) async {
    try {
      if (title.trim().isEmpty) {
        throw ArgumentError('Product title cannot be empty');
      }

      if (categoryId.isEmpty) {
        throw ArgumentError('Category ID cannot be empty');
      }

      if (imageBytes.isEmpty) {
        throw ArgumentError('At least one image is required');
      }

      // 1. If order is 0 or less, auto-assign
      int finalOrder = order;
      if (finalOrder <= 0) {
        final existing = await getProducts();
        finalOrder = existing.length + 1;
      }

      // 2. Handle SKU and auto-generated fields
      final finalSku = sku.isEmpty
          ? 'PSR-${DateTime.now().millisecondsSinceEpoch}'
          : sku;

      // 3. Create document with initial data
      final product = Product(
        id: '', // Firestore will generate
        title: title.trim(),
        description: description.trim(),
        categoryId: categoryId,
        imageUrls: [], // Will update after upload
        order: finalOrder,
        isActive: isActive,
        mrp: mrp,
        sellingPrice: sellingPrice,
        stockCount: stockCount,
        isInStock: stockCount > 0,
        sku: finalSku,
        weight: weight,
        dimensions: dimensions,
        material: material,
        careInstructions: careInstructions,
        tags: tags,
        soldCount: 0,
      );

      final docRef = await FirestoreService.addProduct(product);
      final docId = docRef.id;

      // 4. Upload images
      final urls = await _media.uploadImages(
        docId: docId,
        pathPrefix: 'products',
        files: imageBytes,
      );

      // 5. Update with actual URLs
      if (urls.isNotEmpty) {
        await FirestoreService.updateProduct(docId, {'imageUrls': urls});
      }

      return docId;
    } catch (e) {
      debugPrint('ProductRepository.addProduct error: $e');
      rethrow;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  /// Update product (without images). Use updateProductWithImages for image changes.
  static Future<void> updateProduct({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required int order,
    required bool isActive,
    required double mrp,
    required double sellingPrice,
    required int stockCount,
    required int weight,
    required String material,
    required Map<String, dynamic> dimensions,
    required List<String> careInstructions,
    required List<String> tags,
    required String sku,
  }) async {
    try {
      if (title.trim().isEmpty) {
        throw ArgumentError('Product title cannot be empty');
      }

      if (categoryId.isEmpty) {
        throw ArgumentError('Category ID cannot be empty');
      }

      await FirestoreService.updateProduct(id, {
        'title': title.trim(),
        'description': description.trim(),
        'categoryId': categoryId,
        'order': order,
        'isActive': isActive,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
        'stockCount': stockCount,
        'isInStock': stockCount > 0,
        'weight': weight,
        'sku': sku,
        'material': material,
        'dimensions': dimensions,
        'careInstructions': careInstructions,
        'tags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ProductRepository.updateProduct error: $e');
      rethrow;
    }
  }

  /// Update product with new images.
  static Future<void> updateProductWithImages({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required List<Uint8List> imageBytes,
    required int order,
    required bool isActive,
    required double mrp,
    required double sellingPrice,
    required int stockCount,
    required int weight,
    required String material,
    required Map<String, dynamic> dimensions,
    required List<String> careInstructions,
    required List<String> tags,
    required String sku,
  }) async {
    try {
      if (title.trim().isEmpty) {
        throw ArgumentError('Product title cannot be empty');
      }

      if (categoryId.isEmpty) {
        throw ArgumentError('Category ID cannot be empty');
      }

      if (imageBytes.isEmpty) {
        throw ArgumentError('At least one image is required');
      }

      final existing = await getProduct(id);
      if (existing != null && existing.imageUrls.isNotEmpty) {
        await _media.deletePublicUrls(existing.imageUrls);
      }

      // 1. Upload new images
      final urls = await _media.uploadImages(
        docId: id,
        pathPrefix: 'products',
        files: imageBytes,
      );

      // 2. Update document
      final updateData = {
        'title': title.trim(),
        'description': description.trim(),
        'categoryId': categoryId,
        'order': order,
        'isActive': isActive,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
        'stockCount': stockCount,
        'isInStock': stockCount > 0,
        'weight': weight,
        'sku': sku,
        'material': material,
        'dimensions': dimensions,
        'careInstructions': careInstructions,
        'tags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (urls.isNotEmpty) {
        updateData['imageUrls'] = urls;
      }

      await FirestoreService.updateProduct(id, updateData);
    } catch (e) {
      debugPrint('ProductRepository.updateProductWithImages error: $e');
      rethrow;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  /// Delete product by ID.
  static Future<void> deleteProduct(String id) async {
    try {
      if (id.isEmpty) {
        throw ArgumentError('Product ID cannot be empty');
      }

      final existing = await getProduct(id);
      if (existing != null && existing.imageUrls.isNotEmpty) {
        await _media.deletePublicUrls(existing.imageUrls);
      }

      await FirestoreService.deleteProduct(id);
    } catch (e) {
      debugPrint('ProductRepository.deleteProduct error: $e');
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
      final products = await FirestoreService.getAllProducts();
      return !products.any(
        (p) =>
            p.title.toLowerCase() == title.toLowerCase() &&
            (excludeId == null || p.id != excludeId),
      );
    } catch (e) {
      debugPrint('ProductRepository.isProductTitleUnique error: $e');
      return false;
    }
  }
}
