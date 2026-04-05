import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String message;
  final String status; // unread / read
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SupportMessage.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return SupportMessage(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'unread',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'message': message,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
