import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────
  // WRITE
  // ─────────────────────────────────────────────────

  static Future<void> sendNotification({
    required String audience,
    required String recipientId,
    required String title,
    required String body,
    required String category,
    String entityType = '',
    String entityId = '',
  }) async {
    try {
      await _db.collection('notifications').add({
        'audience': audience,
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'category': category,
        'entityType': entityType,
        'entityId': entityId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NotificationRepository.sendNotification error: $e');
    }
  }

  static Future<void> markRead(String id) async {
    if (id.trim().isEmpty) return;
    await _db.collection('notifications').doc(id).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markAllReadForUser(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .where('recipientId', isEqualTo: userId)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      // Also mark 'all' audience unread
      final allSnap = await _db
          .collection('notifications')
          .where('audience', isEqualTo: 'all')
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in allSnap.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('NotificationRepository.markAllReadForUser error: $e');
    }
  }

  static Future<void> deleteNotification(String id) async {
    try {
      await _db.collection('notifications').doc(id).delete();
    } catch (e) {
      debugPrint('NotificationRepository.deleteNotification error: $e');
    }
  }

  // ─────────────────────────────────────────────────
  // READ — CUSTOMER
  // ─────────────────────────────────────────────────

  /// Stream of notifications for a specific user (personal + all-audience)
  static Stream<List<AppNotification>> watchForUser(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    // Personal notifications
    final personal = _db
        .collection('notifications')
        .where('audience', isEqualTo: 'user')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromDoc).toList());

    // Combine personal + broadcast via asyncMap
    return personal.asyncMap((personalList) async {
      try {
        final snap = await _db
            .collection('notifications')
            .where('audience', isEqualTo: 'all')
            // Removing orderBy to prevent missing composite index errors on Firebase
            .limit(30)
            .get();
        final broadcastList = snap.docs.map(AppNotification.fromDoc).toList();
        final combined = [...personalList, ...broadcastList];
        combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return combined;
      } catch (_) {
        return personalList;
      }
    });
  }

  /// Unread count for badge — personal + broadcast
  static Future<int> getUnreadCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final personal = await _db
          .collection('notifications')
          .where('audience', isEqualTo: 'user')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      final broadcast = await _db
          .collection('notifications')
          .where('audience', isEqualTo: 'all')
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return (personal.count ?? 0) + (broadcast.count ?? 0);
    } catch (e) {
      return 0;
    }
  }

  // ─────────────────────────────────────────────────
  // READ — ADMIN
  // ─────────────────────────────────────────────────

  static Future<List<AppNotification>> getForUser(String userId) async {
    try {
      if (userId.isEmpty) return const [];
      final snap = await _db
          .collection('notifications')
          .where('audience', isEqualTo: 'user')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(AppNotification.fromDoc).toList();
    } catch (e) {
      debugPrint('NotificationRepository.getForUser error: $e');
      return const [];
    }
  }

  static Stream<List<AppNotification>> watchAllForAdmin() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromDoc).toList());
  }

  static Future<List<AppNotification>> getForAdmins() async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('audience', isEqualTo: 'admin')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(AppNotification.fromDoc).toList();
    } catch (e) {
      debugPrint('NotificationRepository.getForAdmins error: $e');
      return const [];
    }
  }
}
