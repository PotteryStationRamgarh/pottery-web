import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../models/app_config.dart';

/// Single source of truth for reading/writing branding, contact, content,
/// and social documents inside the `app_config` Firestore collection.
///
/// All writes use SetOptions(merge: true) — fields not included in a partial
/// save are NEVER deleted from Firestore.
class AdminBrandingRepository {
  AdminBrandingRepository._();

  static final _db  = FirebaseFirestore.instance;
  static const _col = 'app_config';

  // ── READ ──────────────────────────────────────────────────────────────────

  static Future<AppBranding> getBranding() async {
    try {
      final doc = await _db.collection(_col).doc('branding').get();
      if (doc.exists && doc.data() != null) return AppBranding.fromMap(doc.data()!);
      return AppBranding.empty();
    } catch (e) {
      debugPrint('AdminBrandingRepository.getBranding error: $e');
      return AppBranding.empty();
    }
  }

  static Future<AppContact> getContact() async {
    try {
      final doc = await _db.collection(_col).doc('contact').get();
      if (doc.exists && doc.data() != null) return AppContact.fromMap(doc.data()!);
      return AppContact.empty();
    } catch (e) {
      debugPrint('AdminBrandingRepository.getContact error: $e');
      return AppContact.empty();
    }
  }

  static Future<AppContent> getContent() async {
    try {
      final doc = await _db.collection(_col).doc('content').get();
      if (doc.exists && doc.data() != null) return AppContent.fromMap(doc.data()!);
      return AppContent.empty();
    } catch (e) {
      debugPrint('AdminBrandingRepository.getContent error: $e');
      return AppContent.empty();
    }
  }

  static Future<AppSocial> getSocial() async {
    try {
      final doc = await _db.collection(_col).doc('social').get();
      if (doc.exists && doc.data() != null) return AppSocial.fromMap(doc.data()!);
      return AppSocial.empty();
    } catch (e) {
      debugPrint('AdminBrandingRepository.getSocial error: $e');
      return AppSocial.empty();
    }
  }

  /// Fetches all four docs in parallel.
  static Future<BrandingPageData> fetchAll() async {
    final results = await Future.wait([
      getBranding(),
      getContact(),
      getContent(),
      getSocial(),
    ]);
    return BrandingPageData(
      branding: results[0] as AppBranding,
      contact:  results[1] as AppContact,
      content:  results[2] as AppContent,
      social:   results[3] as AppSocial,
    );
  }

  // ── WRITE — all use merge: true ───────────────────────────────────────────

  static Future<void> saveAll({
    required Map<String, dynamic> branding,
    required Map<String, dynamic> contact,
    required Map<String, dynamic> content,
    required Map<String, dynamic> social,
  }) async {
    await Future.wait([
      _db.collection(_col).doc('branding').set(branding, SetOptions(merge: true)),
      _db.collection(_col).doc('contact') .set(contact,  SetOptions(merge: true)),
      _db.collection(_col).doc('content') .set(content,  SetOptions(merge: true)),
      _db.collection(_col).doc('social')  .set(social,   SetOptions(merge: true)),
    ]);
  }
}

class BrandingPageData {
  final AppBranding branding;
  final AppContact  contact;
  final AppContent  content;
  final AppSocial   social;

  const BrandingPageData({
    required this.branding,
    required this.contact,
    required this.content,
    required this.social,
  });
}