import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/support_message.dart';
import 'notification_repository.dart';
import '../services/system_email_service.dart';

class SupportRepository {
  SupportRepository._();

  static final _db = FirebaseFirestore.instance;

  static Future<void> submitRequest(SupportMessage message) async {
    try {
      final docRef = message.id.isEmpty
          ? _db.collection('support_messages').doc()
          : _db.collection('support_messages').doc(message.id);
      await docRef.set(message.toMap(), SetOptions(merge: true));
      if (message.userId.isNotEmpty) {
        await NotificationRepository.sendNotification(
          audience: 'user',
          recipientId: message.userId,
          title: 'Support request received',
          body: 'Your ${message.type} request is now open with the team.',
          category: 'support',
          entityType: 'support_message',
          entityId: docRef.id,
        );
      }
      await NotificationRepository.sendNotification(
        audience: 'admin',
        recipientId: '',
        title: 'New ${message.type} request',
        body: '${message.name} submitted a ${message.type} request.',
        category: 'support',
        entityType: 'support_message',
        entityId: docRef.id,
      );
      await SystemEmailService.queueEmail(
        to: message.email,
        from: SystemEmailService.supportAddress,
        subject: 'Support request received',
        body:
            'Your ${message.type} request has been received by Pottery Station Ramgarh. The team will respond from the dashboard.',
        type: 'support_request',
        relatedEntityId: docRef.id,
        relatedEntityType: 'support_message',
      );
    } catch (e) {
      debugPrint('SupportRepository.submitRequest error: $e');
      rethrow;
    }
  }

  static Future<List<SupportMessage>> getForUser(String userId) async {
    try {
      if (userId.isEmpty) return const [];
      final snap = await _db
          .collection('support_messages')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(SupportMessage.fromDoc).toList();
    } catch (e) {
      debugPrint('SupportRepository.getForUser error: $e');
      return const [];
    }
  }

  static Future<List<SupportMessage>> getAll() async {
    try {
      final snap = await _db
          .collection('support_messages')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(SupportMessage.fromDoc).toList();
    } catch (e) {
      debugPrint('SupportRepository.getAll error: $e');
      return const [];
    }
  }

  static Future<void> updateStatus(
    String id,
    String status, {
    String resolutionNote = '',
  }) async {
    try {
      await _db.collection('support_messages').doc(id).set({
        'status': status,
        'resolutionNote': resolutionNote,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final updatedDoc = await _db.collection('support_messages').doc(id).get();
      if (!updatedDoc.exists) return;
      final message = SupportMessage.fromDoc(updatedDoc);
      if (message.userId.isNotEmpty) {
        await NotificationRepository.sendNotification(
          audience: 'user',
          recipientId: message.userId,
          title: 'Support request updated',
          body: resolutionNote.isNotEmpty
              ? resolutionNote
              : 'Your ${message.type} request is now $status.',
          category: 'support',
          entityType: 'support_message',
          entityId: id,
        );
      }
    } catch (e) {
      debugPrint('SupportRepository.updateStatus error: $e');
      rethrow;
    }
  }
}
