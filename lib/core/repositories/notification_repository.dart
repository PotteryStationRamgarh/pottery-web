import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static final _db = FirebaseFirestore.instance;

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

  static Future<void> markRead(String id) async {
    if (id.trim().isEmpty) return;
    await _db.collection('notifications').doc(id).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
