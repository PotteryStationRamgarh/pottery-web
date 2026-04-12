import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String audience;
  final String recipientId;
  final String title;
  final String body;
  final String category;
  final String entityType;
  final String entityId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.audience,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.category,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      audience: map['audience'] as String? ?? 'user',
      recipientId: map['recipientId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'audience': audience,
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'category': category,
      'entityType': entityType,
      'entityId': entityId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}
