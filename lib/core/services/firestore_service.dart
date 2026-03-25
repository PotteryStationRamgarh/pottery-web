import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_config.dart';
import '../../models/product.dart';
import '../../models/app_user.dart';
import '../../models/support_message.dart';

/// FirestoreService — only class that talks directly to Firestore.
///
/// Collections:
/// app_config/         → branding, contact, content, social, features, exhibition
/// users/{uid}         → email, role, createdAt
/// categories/         → name, imageUrl, order, isActive
/// products/           → title, description, imageUrls[], categoryId, order, isActive
/// exclusive_products/ → title, description, imageUrls[], totalPieces, hasCertificate
/// support_messages/   → userId, name, email, message, status, createdAt
class FirestoreService {
  FirestoreService._();

  static final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // APP CONFIG — individual fetchers
  // ─────────────────────────────────────────

  static Future<AppBranding> getBranding() async {
    try {
      final doc = await _db.collection('app_config').doc('branding').get();
      if (doc.exists && doc.data() != null) {
        return AppBranding.fromMap(doc.data()!);
      }
      return AppBranding.empty();
    } catch (e) {
      debugPrint('getBranding error: $e');
      return AppBranding.empty();
    }
  }

  static Future<AppContact> getContact() async {
    try {
      final doc = await _db.collection('app_config').doc('contact').get();
      if (doc.exists && doc.data() != null) {
        return AppContact.fromMap(doc.data()!);
      }
      return AppContact.empty();
    } catch (e) {
      debugPrint('getContact error: $e');
      return AppContact.empty();
    }
  }

  static Future<AppContent> getContent() async {
    try {
      final doc = await _db.collection('app_config').doc('content').get();
      if (doc.exists && doc.data() != null) {
        return AppContent.fromMap(doc.data()!);
      }
      return AppContent.empty();
    } catch (e) {
      debugPrint('getContent error: $e');
      return AppContent.empty();
    }
  }

  static Future<AppSocial> getSocial() async {
    try {
      final doc = await _db.collection('app_config').doc('social').get();
      if (doc.exists && doc.data() != null) {
        return AppSocial.fromMap(doc.data()!);
      }
      return AppSocial.empty();
    } catch (e) {
      debugPrint('getSocial error: $e');
      return AppSocial.empty();
    }
  }

  static Future<AppFeatures> getFeatures() async {
    try {
      final doc = await _db.collection('app_config').doc('features').get();
      if (doc.exists && doc.data() != null) {
        return AppFeatures.fromMap(doc.data()!);
      }
      return AppFeatures.empty();
    } catch (e) {
      debugPrint('getFeatures error: $e');
      return AppFeatures.empty();
    }
  }

  static Future<AppExhibition> getExhibition() async {
    try {
      final doc = await _db.collection('app_config').doc('exhibition').get();
      if (doc.exists && doc.data() != null) {
        return AppExhibition.fromMap(doc.data()!);
      }
      return AppExhibition.empty();
    } catch (e) {
      debugPrint('getExhibition error: $e');
      return AppExhibition.empty();
    }
  }

  // ─────────────────────────────────────────
  // APP CONFIG — fetch all in parallel
  // Called once by AppConfigProvider on init
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getAllConfig() async {
    try {
      final results = await Future.wait([
        getBranding(),
        getContact(),
        getContent(),
        getSocial(),
        getFeatures(),
        getExhibition(),
      ]);
      return {
        'branding':   results[0] as AppBranding,
        'contact':    results[1] as AppContact,
        'content':    results[2] as AppContent,
        'social':     results[3] as AppSocial,
        'features':   results[4] as AppFeatures,
        'exhibition': results[5] as AppExhibition,
      };
    } catch (e) {
      debugPrint('getAllConfig error: $e');
      return {
        'branding':   AppBranding.empty(),
        'contact':    AppContact.empty(),
        'content':    AppContent.empty(),
        'social':     AppSocial.empty(),
        'features':   AppFeatures.empty(),
        'exhibition': AppExhibition.empty(),
      };
    }
  }

  // ─────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────

  static Future<List<ProductCategory>> getCategories() async {
    try {
      final snap = await _db
          .collection('categories')
          .orderBy('order')
          .get();
      return snap.docs.map(ProductCategory.fromDoc).toList();
    } catch (e) {
      debugPrint('getCategories error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────

  static Future<List<Product>> getProductsByCategory(
      String categoryId) async {
    try {
      final snap = await _db
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('order')
          .get();
      return snap.docs.map(Product.fromDoc).toList();
    } catch (e) {
      debugPrint('getProductsByCategory error: $e');
      return [];
    }
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      final snap = await _db
          .collection('products')
          .orderBy('order')
          .get();
      return snap.docs.map(Product.fromDoc).toList();
    } catch (e) {
      debugPrint('getAllProducts error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // EXCLUSIVE PRODUCTS
  // ─────────────────────────────────────────

  static Future<List<ExclusiveProduct>> getExclusiveProducts() async {
    try {
      final snap = await _db
          .collection('exclusive_products')
          .orderBy('order')
          .get();
      return snap.docs.map(ExclusiveProduct.fromDoc).toList();
    } catch (e) {
      debugPrint('getExclusiveProducts error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // SUPPORT MESSAGES
  // ─────────────────────────────────────────

  static Future<void> sendSupportMessage({
    required String userId,
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      await _db.collection('support_messages').add({
        'userId':    userId,
        'name':      name,
        'email':     email,
        'message':   message,
        'status':    'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendSupportMessage error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // LEGACY — used by auth branding image widget
  // settings/branding → loginImage, signupImage
  // ─────────────────────────────────────────

  static Future<void> setLoginImage(String url) async {
    try {
      await _db.collection('settings').doc('branding').set(
        {'loginImage': url},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('setLoginImage error: $e');
      rethrow;
    }
  }

  static Future<void> setSignupImage(String url) async {
    try {
      await _db.collection('settings').doc('branding').set(
        {'signupImage': url},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('setSignupImage error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getBrandingSettings() async {
    try {
      final doc =
          await _db.collection('settings').doc('branding').get();
      if (doc.exists && doc.data() != null) return doc.data()!;
      return {};
    } catch (e) {
      debugPrint('getBrandingSettings error: $e');
      return {};
    }
  }

  // ─────────────────────────────────────────
  // ADMIN — UPDATE CONFIG
  // ─────────────────────────────────────────

  static Future<void> updateConfig(String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection('app_config').doc(docId).set(data);
    } catch (e) {
      debugPrint('updateConfig error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // ADMIN — CATEGORIES CRUD
  // ─────────────────────────────────────────

  static Future<DocumentReference> addCategory(ProductCategory category) async {
    return await _db.collection('categories').add(category.toMap());
  }

  static Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(id).update(data);
  }

  static Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // ─────────────────────────────────────────
  // ADMIN — PRODUCTS CRUD
  // ─────────────────────────────────────────

  static Future<DocumentReference> addProduct(Product product) async {
    return await _db.collection('products').add(product.toMap());
  }

  static Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  static Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ─────────────────────────────────────────
  // ADMIN — EXCLUSIVE PRODUCTS CRUD
  // ─────────────────────────────────────────

  static Future<DocumentReference> addExclusiveProduct(ExclusiveProduct product) async {
    return await _db.collection('exclusive_products').add(product.toMap());
  }

  static Future<void> updateExclusiveProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('exclusive_products').doc(id).update(data);
  }

  static Future<void> deleteExclusiveProduct(String id) async {
    await _db.collection('exclusive_products').doc(id).delete();
  }

  // ─────────────────────────────────────────
  // ADMIN — SUPPORT MESSAGES
  // ─────────────────────────────────────────

  static Future<List<SupportMessage>> getSupportMessages() async {
    final snap = await _db.collection('support_messages').orderBy('createdAt', descending: true).get();
    return snap.docs.map(SupportMessage.fromDoc).toList();
  }

  static Future<void> updateSupportMessageStatus(String id, String status) async {
    await _db.collection('support_messages').doc(id).update({'status': status});
  }

  // ─────────────────────────────────────────
  // ADMIN — USERS
  // ─────────────────────────────────────────

  static Future<List<AppUser>> getUsers() async {
    final snap = await _db.collection('users').orderBy('createdAt', descending: true).get();
    return snap.docs.map(AppUser.fromDoc).toList();
  }

  static Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
}