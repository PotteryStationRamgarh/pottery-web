import 'package:cloud_firestore/cloud_firestore.dart';

class CustomOrderModel {
  final String id;
  final String userId; // empty string if guest
  final String name;
  final String email;
  final String phone;
  final String productType;
  final String size;
  final String glazePreference;
  final String glazeFinish;
  final int quantity;
  final String specialNotes;
  final String inspirationImageUrl;
  final String status; // pending, reviewing, quoted, accepted, rejected
  final double quotedPrice; // 0 by default, admin fills after review
  final String adminNotes;
  final DateTime? proposedCreationDate;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String paymentStatus; // pending, paid
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomOrderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.productType,
    required this.size,
    required this.glazePreference,
    this.glazeFinish = '',
    required this.quantity,
    required this.specialNotes,
    this.inspirationImageUrl = '',
    this.status = 'pending',
    this.quotedPrice = 0.0,
    this.adminNotes = '',
    this.proposedCreationDate,
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.paymentStatus = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  factory CustomOrderModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return CustomOrderModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      productType: map['productType'] as String? ?? '',
      size: map['size'] as String? ?? '',
      glazePreference: map['glazePreference'] as String? ?? '',
      glazeFinish: map['glazeFinish'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      specialNotes: map['specialNotes'] as String? ?? '',
      inspirationImageUrl: map['inspirationImageUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      quotedPrice: (map['quotedPrice'] as num?)?.toDouble() ?? 0.0,
      adminNotes: map['adminNotes'] as String? ?? '',
      proposedCreationDate:
          (map['proposedCreationDate'] as Timestamp?)?.toDate(),
      razorpayOrderId: map['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
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
      'productType': productType,
      'size': size,
      'glazePreference': glazePreference,
      'glazeFinish': glazeFinish,
      'quantity': quantity,
      'specialNotes': specialNotes,
      'inspirationImageUrl': inspirationImageUrl,
      'status': status,
      'quotedPrice': quotedPrice,
      'adminNotes': adminNotes,
      'proposedCreationDate': proposedCreationDate != null
          ? Timestamp.fromDate(proposedCreationDate!)
          : null,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
