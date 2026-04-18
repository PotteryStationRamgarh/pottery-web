import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/media_service.dart';
import '../models/exhibition_model.dart';

/// Repository for exhibition data from Firestore
/// Provides priority-sorted streams: Current → Future → Past
/// With date-based sorting within each priority group
class ExhibitionRepository {
  ExhibitionRepository._();

  static final _db = FirebaseFirestore.instance;
  static const String _collection = 'exhibition';
  static final _media = MediaService();

  // ─────────────────────────────────────────────────────────────────
  // STREAMS
  // ─────────────────────────────────────────────────────────────────

  /// Stream of all exhibitions, sorted by priority and date
  /// Respects the Firestore security rules:
  /// - Public read access to exhibitions collection
  /// - Returns data in priority order: active first, then by date
  static Stream<List<ExhibitionModel>> watchAllExhibitions() {
    // Note: This query requires a composite index:
    // Collection: exhibition
    // Fields: isActive (Descending), startDate (Descending)
    return _db
        .collection(_collection)
        .orderBy('isActive', descending: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          final exhibitions = snapshot.docs
              .map((doc) => ExhibitionModel.fromDoc(doc))
              .toList();

          // We keep the memory sort as a fallback and for status grouping
          // until the index is fully built and active.
          exhibitions.sort((a, b) => a.compareTo(b));

          debugPrint(
            'ExhibitionRepository: Loaded ${exhibitions.length} exhibitions: '
            '${exhibitions.where((e) => e.isCurrent).length} current, '
            '${exhibitions.where((e) => e.isFuture).length} future, '
            '${exhibitions.where((e) => e.isPast).length} past',
          );

          return exhibitions;
        })
        .handleError((error, stack) {
          debugPrint('ExhibitionRepository.watchAllExhibitions FATAL ERROR: $error');
          debugPrint('Stack: $stack');
          return <ExhibitionModel>[];
        });
  }

  /// Stream of only current (active) exhibitions
  static Stream<List<ExhibitionModel>> watchCurrentExhibitions() {
    return watchAllExhibitions().map((list) {
      final current = list.where((e) => e.isCurrent).toList();
      debugPrint('ExhibitionRepository: ${current.length} current exhibitions');
      return current;
    });
  }

  /// Stream of only future exhibitions
  static Stream<List<ExhibitionModel>> watchFutureExhibitions() {
    return watchAllExhibitions().map((list) {
      final future = list.where((e) => e.isFuture).toList();
      debugPrint('ExhibitionRepository: ${future.length} future exhibitions');
      return future;
    });
  }

  /// Stream of the first active exhibition (for home screen hero section)
  /// Returns the most recent current exhibition, or first upcoming, or most recent past
  static Stream<ExhibitionModel?> watchActiveExhibition() {
    return watchAllExhibitions().map((list) {
      if (list.isEmpty) return null;
      return list.first; // Already sorted, so first is the active one
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // FUTURES (one-time reads)
  // ─────────────────────────────────────────────────────────────────

  /// Single fetch of all exhibitions (not real-time)
  static Future<List<ExhibitionModel>> fetchAll() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('isActive', descending: true)
          .orderBy('startDate', descending: true)
          .get();
      final exhibitions = snapshot.docs
          .map((doc) => ExhibitionModel.fromDoc(doc))
          .toList();
      exhibitions.sort((a, b) => a.compareTo(b));
      return exhibitions;
    } catch (e) {
      debugPrint('ExhibitionRepository.fetchAll error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // ADMIN OPERATIONS
  // ─────────────────────────────────────────────────────────────────

  /// Add new exhibition with image upload
  static Future<String> addExhibition(
    ExhibitionModel exhibition,
    Uint8List imageBytes,
  ) async {
    try {
      // 1. Create document first to get ID
      final docRef = _db.collection(_collection).doc();
      final docId = docRef.id;

      // 2. Upload image
      final urls = await _media.uploadImages(
        docId: docId,
        pathPrefix: 'exhibition',
        files: [imageBytes],
      );

      if (urls.isEmpty) throw Exception('Image upload failed');

      // 3. Save with image URL
      final finalData = exhibition.toMap();
      finalData['imageUrl'] = urls.first;
      finalData['createdAt'] = FieldValue.serverTimestamp();
      finalData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(finalData);
      return docId;
    } catch (e) {
      debugPrint('ExhibitionRepository.addExhibition error: $e');
      rethrow;
    }
  }

  /// Update exhibition (without image change)
  static Future<void> updateExhibition(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ExhibitionRepository.updateExhibition error: $e');
      rethrow;
    }
  }

  /// Update exhibition with new image
  static Future<void> updateExhibitionWithImage(
    String id,
    Map<String, dynamic> data,
    Uint8List imageBytes,
  ) async {
    try {
      // 1. Upload new image
      final urls = await _media.uploadImages(
        docId: id,
        pathPrefix: 'exhibition',
        files: [imageBytes],
      );

      if (urls.isEmpty) throw Exception('Image upload failed');

      // 2. Update doc
      await _db.collection(_collection).doc(id).update({
        ...data,
        'imageUrl': urls.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ExhibitionRepository.updateExhibitionWithImage error: $e');
      rethrow;
    }
  }

  /// Delete exhibition and its image
  static Future<void> deleteExhibition(ExhibitionModel exhibition) async {
    try {
      if (exhibition.imageUrl.isNotEmpty) {
        await _media.deletePublicUrls([exhibition.imageUrl]);
      }
      await _db.collection(_collection).doc(exhibition.id).delete();
    } catch (e) {
      debugPrint('ExhibitionRepository.deleteExhibition error: $e');
      rethrow;
    }
  }
}
