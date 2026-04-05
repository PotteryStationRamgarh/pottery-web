import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'createdAt': createdAt};
  }
}
