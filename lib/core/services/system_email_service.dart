import 'package:cloud_firestore/cloud_firestore.dart';

class SystemEmailService {
  SystemEmailService._();

  static final _db = FirebaseFirestore.instance;

  static const noReplyAddress = 'no-reply@potterystationramgarh.in';
  static const supportAddress = 'support@potterystationramgarh.in';

  static Future<void> queueEmail({
    required String to,
    required String from,
    required String subject,
    required String body,
    required String type,
    String relatedEntityId = '',
    String relatedEntityType = '',
  }) async {
    if (to.trim().isEmpty) return;

    await _db.collection('system_email_outbox').add({
      'to': to.trim(),
      'from': from,
      'subject': subject,
      'body': body,
      'type': type,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'deliveryMode': 'dummy_queue',
      'status': 'queued',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
