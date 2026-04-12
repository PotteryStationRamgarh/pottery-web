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
  final String
  status; // submitted, in_review, quoted, confirmed, rejected, in_production, ready_to_dispatch, in_transit, delivered
  final double quotedPrice; // 0 by default, admin fills after review
  final String adminNotes;
  final DateTime? proposedCreationDate;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String paymentStatus; // pending, paid
  final DateTime? cleanupAfter;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<StatusHistoryEntry> statusHistory;

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
    this.status = 'submitted',
    this.quotedPrice = 0.0,
    this.adminNotes = '',
    this.proposedCreationDate,
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.paymentStatus = 'pending',
    this.cleanupAfter,
    required this.createdAt,
    this.updatedAt,
    this.statusHistory = const [],
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
      status: normalizeStatus(map['status'] as String? ?? 'submitted'),
      quotedPrice: (map['quotedPrice'] as num?)?.toDouble() ?? 0.0,
      adminNotes: map['adminNotes'] as String? ?? '',
      proposedCreationDate: (map['proposedCreationDate'] as Timestamp?)
          ?.toDate(),
      razorpayOrderId: map['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      cleanupAfter: (map['cleanupAfter'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      statusHistory: (map['statusHistory'] as List? ?? [])
          .map((e) => StatusHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
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
      'cleanupAfter': cleanupAfter != null
          ? Timestamp.fromDate(cleanupAfter!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    };
  }

  static String normalizeStatus(String raw) {
    switch (raw) {
      case 'pending':
        return 'submitted';
      case 'reviewing':
        return 'in_review';
      case 'accepted':
        return 'confirmed';
      case 'packed':
        return 'ready_to_dispatch';
      case 'shipped':
        return 'in_transit';
      case 'finished':
        return 'ready_to_dispatch';
      default:
        return raw;
    }
  }

  String get displayStatus {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'in_review':
        return 'Set To Review';
      case 'quoted':
        return 'Quoted';
      case 'confirmed':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'in_production':
        return 'In Production';
      case 'ready_to_dispatch':
        return 'Ready To Dispatch';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}

class StatusHistoryEntry {
  final String status;
  final DateTime timestamp;
  final String note;

  StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    this.note = '',
  });

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: CustomOrderModel.normalizeStatus(
        map['status'] as String? ?? 'submitted',
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}
