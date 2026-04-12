import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String displayName;
  final String phoneNumber;
  final String phoneVerificationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? phoneVerifiedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName = '',
    this.phoneNumber = '',
    this.phoneVerificationStatus = 'not_started',
    required this.createdAt,
    this.updatedAt,
    this.phoneVerifiedAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'customer',
      displayName: map['displayName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      phoneVerificationStatus:
          map['phoneVerificationStatus'] as String? ?? 'not_started',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      phoneVerifiedAt: (map['phoneVerifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'phoneVerificationStatus': phoneVerificationStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'phoneVerifiedAt': phoneVerifiedAt != null
          ? Timestamp.fromDate(phoneVerifiedAt!)
          : null,
    };
  }
}
