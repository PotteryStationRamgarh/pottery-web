import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String message;
  final String type; // support / return / refund / custom-order
  final String status; // open / in_review / resolved / closed
  final String orderId;
  final String resolutionNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportMessage({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone = '',
    this.subject = '',
    required this.message,
    this.type = 'support',
    required this.status,
    this.orderId = '',
    this.resolutionNote = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory SupportMessage.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return SupportMessage(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'support',
      status: map['status'] as String? ?? 'open',
      orderId: map['orderId'] as String? ?? '',
      resolutionNote: map['resolutionNote'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'message': message,
      'type': type,
      'status': status,
      'orderId': orderId,
      'resolutionNote': resolutionNote,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
