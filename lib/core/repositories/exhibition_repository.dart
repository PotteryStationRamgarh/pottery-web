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
          .get(const GetOptions(source: Source.server));
      return snap.docs.map(Exhibition.fromDoc).toList();
    } catch (e) {
      debugPrint('ExhibitionRepository.getAll error: $e');
      return [];
    }
  }

  /// First active exhibition, or Exhibition.empty() if none.
  /// Used by ExhibitionProvider → customer home screen.
  /// 
  /// Filters exhibitions that:
  /// 1. Have isActive == true
  /// 2. Have valid startDate and endDate
  /// 3. Are currently within or approaching the date range
  static Future<Exhibition> getActive() async {
    try {
      final snap = await _db.collection(_col).get(const GetOptions(source: Source.server));
      if (snap.docs.isEmpty) return Exhibition.empty();
      
      final all = snap.docs.map(Exhibition.fromDoc).toList();
      final now = DateTime.now();

      // Priority 1: Next Upcoming
      final upcoming = all
          .where((e) => e.isActive && e.startDate != null && e.startDate!.isAfter(now))
          .toList()
        ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
      if (upcoming.isNotEmpty) return upcoming.first;

      // Priority 2: Current / Live
      final current = all
          .where((e) => e.isActive && e.isCurrentlyActive)
          .toList()
        ..sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)));
      if (current.isNotEmpty) return current.first;

      // Priority 3: Most Recent Past
      final past = all
          .where((e) => e.isActive && e.endDate != null && e.endDate!.isBefore(now))
          .toList()
        ..sort((a, b) => b.endDate!.compareTo(a.endDate!));
      if (past.isNotEmpty) return past.first;

      return Exhibition.empty();
    } catch (e) {
      debugPrint('ExhibitionRepository.getActive error: $e');
      return Exhibition.empty();
    }
  }

  /// Get current/active exhibition (within date range and isActive==true)
  static Future<Exhibition?> getCurrent() async {
    try {
      final snap = await _db
          .collection(_col)
          .where('isActive', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
      
      if (snap.docs.isEmpty) return null;
      
      final active = snap.docs
          .map(Exhibition.fromDoc)
          .where((e) => e.isCurrentlyActive)
          .toList();
      
      if (active.isEmpty) return null;
      active.sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)));
      return active.first;
    } catch (e) {
      debugPrint('ExhibitionRepository.getCurrent error: $e');
      return null;
    }
  }

  /// Get next upcoming exhibition (startDate > now)
  static Future<Exhibition?> getUpcoming() async {
    try {
      final now = DateTime.now();
      final snap = await _db
          .collection(_col)
          .where('isActive', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
      
      final upcoming = snap.docs
          .map(Exhibition.fromDoc)
          .where((e) => e.startDate != null && e.startDate!.isAfter(now))
          .toList();
      
      if (upcoming.isEmpty) return null;
      upcoming.sort((a, b) => a.startDate!.compareTo(b.startDate!));
      return upcoming.first;
    } catch (e) {
      debugPrint('ExhibitionRepository.getUpcoming error: $e');
      return null;
    }
  }

  /// Get all upcoming exhibitions
  static Future<List<Exhibition>> getFutureExhibitions() async {
    try {
      final now = DateTime.now();
      final snap = await _db
          .collection(_col)
          .where('isActive', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
      
      final future = snap.docs
          .map(Exhibition.fromDoc)
          .where((e) => e.startDate != null && e.startDate!.isAfter(now))
          .toList();
      future.sort((a, b) => a.startDate!.compareTo(b.startDate!));
      return future;
    } catch (e) {
      debugPrint('ExhibitionRepository.getFutureExhibitions error: $e');
      return [];
    }
  }

  /// Get all past exhibitions
  static Future<List<Exhibition>> getPastExhibitions() async {
    try {
      final now = DateTime.now();
      final snap = await _db.collection(_col).get(const GetOptions(source: Source.server));
      
      final past = snap.docs
          .map(Exhibition.fromDoc)
          .where((e) => e.endDate != null && e.endDate!.isBefore(now))
          .toList();
      past.sort((a, b) => b.endDate!.compareTo(a.endDate!));
      return past;
    } catch (e) {
      debugPrint('ExhibitionRepository.getPastExhibitions error: $e');
      return [];
    }
  }

  /// Get exhibitions categorized by status: current, future, past
  static Future<Map<String, dynamic>> getCategorized() async {
    try {
      final current = await getCurrent();
      final future = await getFutureExhibitions();
      final past = await getPastExhibitions();
      
      return {
        'current': current,
        'future': future,
        'past': past,
      };
    } catch (e) {
      debugPrint('ExhibitionRepository.getCategorized error: $e');
      return {'current': null, 'future': [], 'past': []};
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

  /// Deletes a specific exhibition by id.
  static Future<void> deleteExhibition(String id) async {
    try {
      await _db.collection(_col).doc(id).delete();
    } catch (e) {
      debugPrint('ExhibitionRepository.deleteExhibition error: $e');
      rethrow;
    }
  }

  /// Deletes all exhibitions where endDate is more than 30 days ago.
  /// Call this once on app start from admin layout initState.
  static Future<void> deleteOldExhibitions() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final snap = await _db.collection(_col).get(const GetOptions(source: Source.server));
      for (final doc in snap.docs) {
        final exh = Exhibition.fromDoc(doc);
        if (exh.endDate != null && exh.endDate!.isBefore(cutoff)) {
          await _db.collection(_col).doc(doc.id).delete();
          debugPrint('Auto-deleted old exhibition: ${exh.title}');
        }
      }
    } catch (e) {
      debugPrint('deleteOldExhibitions error: $e');
    }
  }
}