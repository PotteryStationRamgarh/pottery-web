import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String customerEmail;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod; // card, upi, netbanking
  final String paymentStatus; // pending, paid, failed
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String
  orderStatus; // pending, confirmed, in_production, in_transit, delivered, cancelled
  final String addressId;
  final Map<String, dynamic> addressSnapshot;
  final String giftNote;
  final String shiprocketOrderId;
  final String trackingNumber;
  final String courierName;
  final String adminNotes;
  final DateTime? estimatedDelivery;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderStatusEntry> statusTimeline;

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.orderStatus,
    required this.addressId,
    this.addressSnapshot = const {},
    required this.giftNote,
    required this.shiprocketOrderId,
    required this.trackingNumber,
    required this.courierName,
    this.adminNotes = '',
    this.estimatedDelivery,
    required this.createdAt,
    this.updatedAt,
    this.statusTimeline = const [],
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      items:
          (map['items'] as List?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      razorpayOrderId: map['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? '',
      orderStatus: normalizeStatus(map['orderStatus'] as String? ?? 'pending'),
      addressId: map['addressId'] as String? ?? '',
      addressSnapshot: Map<String, dynamic>.from(
        map['addressSnapshot'] as Map? ?? const {},
      ),
      giftNote: map['giftNote'] as String? ?? '',
      shiprocketOrderId: map['shiprocketOrderId'] as String? ?? '',
      trackingNumber: map['trackingNumber'] as String? ?? '',
      courierName: map['courierName'] as String? ?? '',
      adminNotes: map['adminNotes'] as String? ?? '',
      estimatedDelivery: (map['estimatedDelivery'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      statusTimeline: (map['statusTimeline'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                OrderStatusEntry.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'orderStatus': orderStatus,
      'addressId': addressId,
      'addressSnapshot': addressSnapshot,
      'giftNote': giftNote,
      'shiprocketOrderId': shiprocketOrderId,
      'trackingNumber': trackingNumber,
      'courierName': courierName,
      'adminNotes': adminNotes,
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'statusTimeline': statusTimeline.map((entry) => entry.toMap()).toList(),
    };
  }

  static String normalizeStatus(String raw) {
    switch (raw) {
      case 'processing':
        return 'pending';
      case 'shipped':
        return 'in_transit';
      default:
        return raw;
    }
  }

  String get displayStatus {
    switch (orderStatus) {
      case 'pending':
        return 'Pending Review';
      case 'confirmed':
        return 'Confirmed';
      case 'in_production':
        return 'Preparing';
      case 'ready_to_dispatch':
        return 'Ready To Dispatch';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'return_requested':
        return 'Return Requested';
      case 'refund_requested':
        return 'Refund Requested';
      case 'refunded':
        return 'Refunded';
      default:
        return orderStatus.replaceAll('_', ' ');
    }
  }
}

class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final int qty;
  final double sellingPrice;
  final String sku;
  final bool isExclusive;

  OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.qty,
    required this.sellingPrice,
    required this.sku,
    this.isExclusive = false,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      qty: map['qty'] as int? ?? 1,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      sku: map['sku'] as String? ?? '',
      isExclusive: map['isExclusive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'qty': qty,
      'sellingPrice': sellingPrice,
      'sku': sku,
      'isExclusive': isExclusive,
    };
  }
}

class OrderStatusEntry {
  final String status;
  final String title;
  final String description;
  final DateTime createdAt;

  const OrderStatusEntry({
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory OrderStatusEntry.fromMap(Map<String, dynamic> map) {
    return OrderStatusEntry(
      status: map['status'] as String? ?? 'pending',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
