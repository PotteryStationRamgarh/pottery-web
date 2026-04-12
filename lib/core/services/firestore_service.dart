import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_config.dart';
import '../../models/product.dart';
import '../../models/app_user.dart';
import '../../models/support_message.dart';

/// FirestoreService — handles app_config, categories, products,
/// exclusive_products, support_messages, users, and settings collections.
///
/// The `exhibition` collection is handled exclusively by ExhibitionRepository.
/// Do NOT add exhibition calls here.
class FirestoreService {
  FirestoreService._();

  static final _db = FirebaseFirestore.instance;
  static GetOptions _getOptions(bool forceRefresh) =>
      GetOptions(source: forceRefresh ? Source.server : Source.serverAndCache);

  // ── APP CONFIG — individual fetchers ─────────────────────────────────────

  static Future<AppBranding> getBranding({bool forceRefresh = false}) async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('branding')
          .get(_getOptions(forceRefresh));
      if (doc.exists && doc.data() != null) {
        return AppBranding.fromMap(doc.data()!);
      }
      return AppBranding.empty();
    } catch (e) {
      debugPrint('getBranding error: $e');
      return AppBranding.empty();
    }
  }

  static Future<AppContact> getContact({bool forceRefresh = false}) async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('contact')
          .get(_getOptions(forceRefresh));
      if (doc.exists && doc.data() != null) {
        return AppContact.fromMap(doc.data()!);
      }
      return AppContact.empty();
    } catch (e) {
      debugPrint('getContact error: $e');
      return AppContact.empty();
    }
  }

  static Future<AppContent> getContent({bool forceRefresh = false}) async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('content')
          .get(_getOptions(forceRefresh));
      if (doc.exists && doc.data() != null) {
        return AppContent.fromMap(doc.data()!);
      }
      return AppContent.empty();
    } catch (e) {
      debugPrint('getContent error: $e');
      return AppContent.empty();
    }
  }

  static Future<AppSocial> getSocial({bool forceRefresh = false}) async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('social')
          .get(_getOptions(forceRefresh));
      if (doc.exists && doc.data() != null) {
        return AppSocial.fromMap(doc.data()!);
      }
      return AppSocial.empty();
    } catch (e) {
      debugPrint('getSocial error: $e');
      return AppSocial.empty();
    }
  }

  static Future<AppFeatures> getFeatures({bool forceRefresh = false}) async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('features')
          .get(_getOptions(forceRefresh));
      if (doc.exists && doc.data() != null) {
        return AppFeatures.fromMap(doc.data()!);
      }
      return AppFeatures.empty();
    } catch (e) {
      debugPrint('getFeatures error: $e');
      return AppFeatures.empty();
    }
  }

  // ── APP CONFIG — fetch all in parallel ───────────────────────────────────

  static Future<Map<String, dynamic>> getAllConfig({
    bool forceRefresh = false,
  }) async {
    try {
      final results = await Future.wait([
        getBranding(forceRefresh: forceRefresh),
        getContact(forceRefresh: forceRefresh),
        getContent(forceRefresh: forceRefresh),
        getSocial(forceRefresh: forceRefresh),
        getFeatures(forceRefresh: forceRefresh),
      ]);
      return {
        'branding': results[0] as AppBranding,
        'contact': results[1] as AppContact,
        'content': results[2] as AppContent,
        'social': results[3] as AppSocial,
        'features': results[4] as AppFeatures,
        // exhibition removed — now in its own collection via ExhibitionRepository
      };
    } catch (e) {
      debugPrint('getAllConfig error: $e');
      return {
        'branding': AppBranding.empty(),
        'contact': AppContact.empty(),
        'content': AppContent.empty(),
        'social': AppSocial.empty(),
        'features': AppFeatures.empty(),
      };
    }
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────

  static Future<List<ProductCategory>> getCategories({
    bool forceRefresh = false,
  }) async {
    try {
      final snap = await _db
          .collection('categories')
          .orderBy('order')
          .get(_getOptions(forceRefresh));
      return snap.docs.map(ProductCategory.fromDoc).toList();
    } catch (e) {
      debugPrint('getCategories error: $e');
      return [];
    }
  }

  // ── PRODUCTS ──────────────────────────────────────────────────────────────

  static Future<List<Product>> getProductsByCategory(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    try {
      final snap = await _db
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('order')
          .get(_getOptions(forceRefresh));
      return snap.docs.map(Product.fromDoc).toList();
    } catch (e) {
      debugPrint('getProductsByCategory error: $e');
      return [];
    }
  }

  static Future<List<Product>> getAllProducts({
    bool forceRefresh = false,
  }) async {
    try {
      final snap = await _db
          .collection('products')
          .orderBy('order')
          .get(_getOptions(forceRefresh));
      return snap.docs.map(Product.fromDoc).toList();
    } catch (e) {
      debugPrint('getAllProducts error: $e');
      return [];
    }
  }

  // ── EXCLUSIVE PRODUCTS ────────────────────────────────────────────────────

  static Future<List<ExclusiveProduct>> getExclusiveProducts({
    bool forceRefresh = false,
  }) async {
    try {
      final snap = await _db
          .collection('exclusive_products')
          .orderBy('order')
          .get(_getOptions(forceRefresh));
      return snap.docs.map(ExclusiveProduct.fromDoc).toList();
    } catch (e) {
      debugPrint('getExclusiveProducts error: $e');
      return [];
    }
  }

  // ── SUPPORT MESSAGES ──────────────────────────────────────────────────────

  static Future<void> sendSupportMessage({
    required String userId,
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      await _db.collection('support_messages').add({
        'userId': userId,
        'name': name,
        'email': email,
        'message': message,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendSupportMessage error: $e');
      rethrow;
    }
  }

  // ── LEGACY settings/branding ──────────────────────────────────────────────

  static Future<void> setLoginImage(String url) async {
    try {
      await _db.collection('settings').doc('branding').set({
        'loginImage': url,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('setLoginImage error: $e');
      rethrow;
    }
  }

  static Future<void> setSignupImage(String url) async {
    try {
      await _db.collection('settings').doc('branding').set({
        'signupImage': url,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('setSignupImage error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getBrandingSettings({
    bool forceRefresh = false,
  }) async {
    try {
      final doc = await _db
          .collection('settings')
          .doc('branding')
          .get(_getOptions(forceRefresh));
      if (doc.exists && doc.data() != null) return doc.data()!;
      return {};
    } catch (e) {
      debugPrint('getBrandingSettings error: $e');
      return {};
    }
  }

  // ── ADMIN — UPDATE CONFIG ─────────────────────────────────────────────────

  /// FIXED: uses merge: true so fields not included in [data] are NOT deleted.
  static Future<void> updateConfig(
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db
          .collection('app_config')
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateConfig error: $e');
      rethrow;
    }
  }

  // ── ADMIN — CATEGORIES CRUD ───────────────────────────────────────────────

  static Future<DocumentReference> addCategory(ProductCategory category) async {
    final docRef = _db.collection('categories').doc();
    await docRef.set(category.toMap(), SetOptions(merge: true));
    return docRef;
  }

  static Future<void> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('categories')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }

  static Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // ── ADMIN — PRODUCTS CRUD ─────────────────────────────────────────────────

  static Future<DocumentReference> addProduct(Product product) async {
    final docRef = _db.collection('products').doc();
    await docRef.set(product.toMap(), SetOptions(merge: true));
    return docRef;
  }

  static Future<void> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('products').doc(id).set(data, SetOptions(merge: true));
  }

  static Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ── ADMIN — EXCLUSIVE PRODUCTS CRUD ──────────────────────────────────────

  static Future<DocumentReference> addExclusiveProduct(
    ExclusiveProduct product,
  ) async {
    final docRef = _db.collection('exclusive_products').doc();
    await docRef.set(product.toMap(), SetOptions(merge: true));
    return docRef;
  }

  static Future<void> updateExclusiveProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('exclusive_products')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }

  static Future<void> deleteExclusiveProduct(String id) async {
    await _db.collection('exclusive_products').doc(id).delete();
  }

  // ── ADMIN — SUPPORT MESSAGES ──────────────────────────────────────────────

  static Future<List<SupportMessage>> getSupportMessages({
    bool forceRefresh = false,
  }) async {
    final snap = await _db
        .collection('support_messages')
        .orderBy('createdAt', descending: true)
        .get(_getOptions(forceRefresh));
    return snap.docs.map(SupportMessage.fromDoc).toList();
  }

  static Future<void> updateSupportMessageStatus(
    String id,
    String status,
  ) async {
    await _db.collection('support_messages').doc(id).update({'status': status});
  }

  // ── ADMIN — USERS ─────────────────────────────────────────────────────────

  static Future<List<AppUser>> getUsers({bool forceRefresh = false}) async {
    final snap = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get(_getOptions(forceRefresh));
    return snap.docs.map(AppUser.fromDoc).toList();
  }

  static Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
}
