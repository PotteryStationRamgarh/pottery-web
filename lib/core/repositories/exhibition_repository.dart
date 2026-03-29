import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/exhibition.dart';

/// Single source of truth for the top-level `exhibition` Firestore collection.
/// No widget, page, or service touches this collection directly — only this file.
class ExhibitionRepository {
  ExhibitionRepository._();

  static final _db  = FirebaseFirestore.instance;
  static const _col = 'exhibition';

  // ── READ ──────────────────────────────────────────────────────────────────

  /// All exhibitions, newest first.
  static Future<List<Exhibition>> getAll() async {
    try {
      final snap = await _db
          .collection(_col)
          .orderBy('startDate', descending: true)
          .get();
      return snap.docs.map(Exhibition.fromDoc).toList();
    } catch (e) {
      debugPrint('ExhibitionRepository.getAll error: $e');
      return [];
    }
  }

  /// First active exhibition, or Exhibition.empty() if none.
  /// Used by ExhibitionProvider → customer home screen.
  static Future<Exhibition> getActive() async {
    try {
      final snap = await _db
          .collection(_col)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return Exhibition.empty();
      return Exhibition.fromDoc(snap.docs.first);
    } catch (e) {
      debugPrint('ExhibitionRepository.getActive error: $e');
      return Exhibition.empty();
    }
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Creates or updates an exhibition.
  /// If [exhibition.id] is empty, creates a new doc and returns its id.
  /// Otherwise updates the existing doc and returns the same id.
  static Future<String> save(Exhibition exhibition) async {
    if (exhibition.id.isEmpty) {
      final ref = await _db.collection(_col).add(exhibition.toMap());
      return ref.id;
    }
    await _db
        .collection(_col)
        .doc(exhibition.id)
        .set(exhibition.toMap(), SetOptions(merge: true));
    return exhibition.id;
  }

  static Future<void> delete(String id) async {
    try {
      await _db.collection(_col).doc(id).delete();
    } catch (e) {
      debugPrint('ExhibitionRepository.delete error: $e');
      rethrow;
    }
  }
}