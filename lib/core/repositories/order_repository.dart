import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/address_model.dart';
import '../../models/order_model.dart';
import 'notification_repository.dart';
import '../services/system_email_service.dart';

class OrderRepository {
  OrderRepository._();

  static final _db = FirebaseFirestore.instance;

  static Future<OrderModel> createOrder({
    required String userId,
    required String customerEmail,
    required String customerPhone,
    required AddressModel address,
    required List<OrderItem> items,
    required double totalAmount,
    String giftNote = '',
  }) async {
    try {
      final docRef = _db.collection('orders').doc();
      final createdAt = DateTime.now();
      final order = OrderModel(
        id: docRef.id,
        userId: userId,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        items: items,
        totalAmount: totalAmount,
        paymentMethod: 'dummy',
        paymentStatus: 'pending',
        razorpayOrderId: 'dummy_${docRef.id}',
        razorpayPaymentId: '',
        orderStatus: 'pending',
        addressId: address.id,
        addressSnapshot: address.toMap(),
        giftNote: giftNote,
        shiprocketOrderId: 'dummy_ship_${docRef.id.substring(0, 8)}',
        trackingNumber: '',
        courierName: '',
        adminNotes: '',
        estimatedDelivery: createdAt.add(const Duration(days: 7)),
        createdAt: createdAt,
        statusTimeline: [
          OrderStatusEntry(
            status: 'pending',
            title: 'Order placed',
            description:
                'Your order has been recorded. Payment and dispatch are running in demo mode for now.',
            createdAt: createdAt,
          ),
        ],
      );

      await docRef.set(order.toMap(), SetOptions(merge: true));

      for (final item in items) {
        final collection = item.isExclusive ? 'exclusive_products' : 'products';
        final productRef = _db.collection(collection).doc(item.productId);
        await _db.runTransaction((txn) async {
          final snap = await txn.get(productRef);
          final data = snap.data() ?? <String, dynamic>{};
          final soldCount = data['soldCount'] as int? ?? 0;
          final stockCount = data['stockCount'] as int? ?? 99;
          txn.set(productRef, {
            'soldCount': soldCount + item.qty,
            'stockCount': stockCount > 0 ? stockCount - item.qty : stockCount,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
      }

      await NotificationRepository.sendNotification(
        audience: 'user',
        recipientId: userId,
        title: 'Order placed successfully',
        body:
            'Order ${docRef.id.substring(0, 8).toUpperCase()} is now pending confirmation.',
        category: 'order',
        entityType: 'order',
        entityId: docRef.id,
      );
      await NotificationRepository.sendNotification(
        audience: 'admin',
        recipientId: '',
        title: 'New order received',
        body: 'A new storefront order needs review.',
        category: 'order',
        entityType: 'order',
        entityId: docRef.id,
      );
      await SystemEmailService.queueEmail(
        to: customerEmail,
        from: SystemEmailService.noReplyAddress,
        subject: 'Your Pottery Station order is in progress',
        body:
            'We have received your order ${docRef.id.substring(0, 8).toUpperCase()}. Payment and delivery are currently demo flows inside the app.',
        type: 'order_confirmation',
        relatedEntityId: docRef.id,
        relatedEntityType: 'order',
      );

      return order;
    } catch (e) {
      debugPrint('OrderRepository.createOrder error: $e');
      rethrow;
    }
  }

  static Future<List<OrderModel>> getOrdersByUser(String userId) async {
    try {
      if (userId.isEmpty) return [];

      final snap = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(OrderModel.fromDoc).toList();
    } catch (e) {
      debugPrint('OrderRepository.getOrdersByUser error: $e');
      return [];
    }
  }

  static Future<List<OrderModel>> getAllOrders() async {
    try {
      final snap = await _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(OrderModel.fromDoc).toList();
    } catch (e) {
      debugPrint('OrderRepository.getAllOrders error: $e');
      return [];
    }
  }

  static Future<void> updateOrderStatus(
    String orderId, {
    required String status,
    String description = '',
    String trackingNumber = '',
    String courierName = '',
    DateTime? estimatedDelivery,
    String adminNotes = '',
  }) async {
    try {
      final docRef = _db.collection('orders').doc(orderId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final order = OrderModel.fromDoc(doc);
      final now = DateTime.now();
      final timeline = [
        ...order.statusTimeline,
        OrderStatusEntry(
          status: status,
          title: _titleForStatus(status),
          description: description.isNotEmpty
              ? description
              : _descriptionForStatus(status),
          createdAt: now,
        ),
      ];

      await docRef.set({
        'orderStatus': status,
        'trackingNumber': trackingNumber.isNotEmpty
            ? trackingNumber
            : order.trackingNumber,
        'courierName': courierName.isNotEmpty ? courierName : order.courierName,
        'estimatedDelivery': estimatedDelivery != null
            ? Timestamp.fromDate(estimatedDelivery)
            : order.estimatedDelivery != null
            ? Timestamp.fromDate(order.estimatedDelivery!)
            : null,
        'adminNotes': adminNotes,
        'statusTimeline': timeline.map((entry) => entry.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await NotificationRepository.sendNotification(
        audience: 'user',
        recipientId: order.userId,
        title: 'Order update: ${_titleForStatus(status)}',
        body: description.isNotEmpty
            ? description
            : _descriptionForStatus(status),
        category: 'order',
        entityType: 'order',
        entityId: orderId,
      );
      await NotificationRepository.sendNotification(
        audience: 'admin',
        recipientId: '',
        title: 'Order status updated',
        body:
            'Order ${orderId.substring(0, 8).toUpperCase()} moved to ${_titleForStatus(status)}.',
        category: 'order',
        entityType: 'order',
        entityId: orderId,
      );
      await SystemEmailService.queueEmail(
        to: order.customerEmail,
        from: SystemEmailService.noReplyAddress,
        subject: 'Order update: ${_titleForStatus(status)}',
        body: description.isNotEmpty
            ? description
            : _descriptionForStatus(status),
        type: 'order_update',
        relatedEntityId: orderId,
        relatedEntityType: 'order',
      );
    } catch (e) {
      debugPrint('OrderRepository.updateOrderStatus error: $e');
      rethrow;
    }
  }

  static String _titleForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'in_production':
        return 'Preparing your order';
      case 'ready_to_dispatch':
        return 'Ready to dispatch';
      case 'in_transit':
        return 'In transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'return_requested':
        return 'Return requested';
      case 'refund_requested':
        return 'Refund requested';
      case 'refunded':
        return 'Refunded';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  static String _descriptionForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'The order has been placed and is waiting for manual review.';
      case 'confirmed':
        return 'The order has been confirmed by the team.';
      case 'in_production':
        return 'The pieces are being prepared for dispatch.';
      case 'ready_to_dispatch':
        return 'The parcel is packed and queued for handoff.';
      case 'in_transit':
        return 'The courier has picked up the parcel. Tracking is demo-powered for now.';
      case 'delivered':
        return 'The order is marked delivered.';
      case 'cancelled':
        return 'The order has been cancelled.';
      case 'return_requested':
        return 'A return request has been submitted from the website.';
      case 'refund_requested':
        return 'A refund request has been submitted from the website.';
      case 'refunded':
        return 'The refund has been marked completed.';
      default:
        return 'The order status has changed.';
    }
  }
}
