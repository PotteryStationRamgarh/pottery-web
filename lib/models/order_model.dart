import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod; // card, upi, netbanking
  final String paymentStatus; // pending, paid, failed
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String orderStatus; // processing, confirmed, shipped, delivered, cancelled
  final String addressId;
  final String giftNote;
  final String shiprocketOrderId;
  final String trackingNumber;
  final String courierName;
  final DateTime? estimatedDelivery;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.orderStatus,
    required this.addressId,
    required this.giftNote,
    required this.shiprocketOrderId,
    required this.trackingNumber,
    required this.courierName,
    this.estimatedDelivery,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      razorpayOrderId: map['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? '',
      orderStatus: map['orderStatus'] as String? ?? 'processing',
      addressId: map['addressId'] as String? ?? '',
      giftNote: map['giftNote'] as String? ?? '',
      shiprocketOrderId: map['shiprocketOrderId'] as String? ?? '',
      trackingNumber: map['trackingNumber'] as String? ?? '',
      courierName: map['courierName'] as String? ?? '',
      estimatedDelivery: (map['estimatedDelivery'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'orderStatus': orderStatus,
      'addressId': addressId,
      'giftNote': giftNote,
      'shiprocketOrderId': shiprocketOrderId,
      'trackingNumber': trackingNumber,
      'courierName': courierName,
      'estimatedDelivery': estimatedDelivery != null ? Timestamp.fromDate(estimatedDelivery!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final int qty;
  final double sellingPrice;
  final String sku;

  OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.qty,
    required this.sellingPrice,
    required this.sku,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      qty: map['qty'] as int? ?? 1,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      sku: map['sku'] as String? ?? '',
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
    };
  }
}
