import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/media_service.dart';
import '../../models/custom_order_model.dart';
import 'notification_repository.dart';
import '../services/system_email_service.dart';

class CustomOrderRepository {
  CustomOrderRepository._();

  static final _db = FirebaseFirestore.instance;
  static final _media = MediaService();

  static Future<void> submitCustomOrder(CustomOrderModel order) async {
    try {
      final isNew = order.id.isEmpty;
      final docRef = isNew
          ? _db.collection('custom_orders').doc()
          : _db.collection('custom_orders').doc(order.id);

      final payload = order.toMap();
      if (isNew) {
        final initialEntry = StatusHistoryEntry(
          status: 'submitted',
          timestamp: DateTime.now(),
          note: 'Order submitted',
        );
        payload['statusHistory'] = [initialEntry.toMap()];
        payload['status'] = 'submitted';
      }

      await docRef.set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CustomOrderRepository.submitCustomOrder error: $e');
      rethrow;
    }
  }

  static Future<void> submitCustomOrderWithImage(
    CustomOrderModel order, {
    Uint8List? inspirationImageBytes,
  }) async {
    try {
      final isNew = order.id.isEmpty;
      final docRef = isNew
          ? _db.collection('custom_orders').doc()
          : _db.collection('custom_orders').doc(order.id);

      final payload = order.toMap();
      if (isNew) {
        final initialEntry = StatusHistoryEntry(
          status: 'submitted',
          timestamp: DateTime.now(),
          note: 'Order submitted with image',
        );
        payload['statusHistory'] = [initialEntry.toMap()];
        payload['status'] = 'submitted';
      }

      if (inspirationImageBytes != null) {
        final urls = await _media.uploadImages(
          docId: docRef.id,
          pathPrefix: 'custom_orders',
          files: [inspirationImageBytes],
        );
        if (urls.isNotEmpty) {
          payload['inspirationImageUrl'] = urls.first;
        }
      }

      await docRef.set(payload, SetOptions(merge: true));

      await NotificationRepository.sendNotification(
        audience: 'admin',
        recipientId: '',
        title: 'New custom order request',
        body:
            '${order.name} submitted a custom request for ${order.productType}.',
        category: 'custom_order',
        entityType: 'custom_order',
        entityId: docRef.id,
      );
      if (order.userId.isNotEmpty) {
        await NotificationRepository.sendNotification(
          audience: 'user',
          recipientId: order.userId,
          title: 'Custom order submitted',
          body: 'Your custom product request is now set to review.',
          category: 'custom_order',
          entityType: 'custom_order',
          entityId: docRef.id,
        );
      }
      await SystemEmailService.queueEmail(
        to: order.email,
        from: SystemEmailService.noReplyAddress,
        subject: 'Custom order received',
        body:
            'Your custom request has been received and is now set to review. We will quote it from the dashboard.',
        type: 'custom_order_submitted',
        relatedEntityId: docRef.id,
        relatedEntityType: 'custom_order',
      );
    } catch (e) {
      debugPrint('CustomOrderRepository.submitCustomOrderWithImage error: $e');
      rethrow;
    }
  }

  static Future<List<CustomOrderModel>> getCustomOrders() async {
    try {
      final snap = await _db
          .collection('custom_orders')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(CustomOrderModel.fromDoc).toList();
    } catch (e) {
      debugPrint('CustomOrderRepository.getCustomOrders error: $e');
      return [];
    }
  }

  static Future<List<CustomOrderModel>> getCustomOrdersByUser(
    String userId,
  ) async {
    try {
      if (userId.isEmpty) return const [];
      final snap = await _db
          .collection('custom_orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(CustomOrderModel.fromDoc).toList();
    } catch (e) {
      debugPrint('CustomOrderRepository.getCustomOrdersByUser error: $e');
      return const [];
    }
  }

  static Future<void> updateCustomOrder(CustomOrderModel order) async {
    try {
      await _db.collection('custom_orders').doc(order.id).set({
        ...order.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CustomOrderRepository.updateCustomOrder error: $e');
      rethrow;
    }
  }

  static Future<void> reviewCustomOrder(
    CustomOrderModel nextOrder, {
    required String note,
  }) async {
    try {
      final docRef = _db.collection('custom_orders').doc(nextOrder.id);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) return;

      final existingOrder = CustomOrderModel.fromDoc(existingDoc);
      final normalizedStatus = CustomOrderModel.normalizeStatus(
        nextOrder.status,
      );
      final shouldScheduleCleanup = normalizedStatus == 'rejected';
      final entry = StatusHistoryEntry(
        status: normalizedStatus,
        timestamp: DateTime.now(),
        note: note,
      );

      await docRef.set({
        ...nextOrder.toMap(),
        'status': normalizedStatus,
        'cleanupAfter': shouldScheduleCleanup
            ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)))
            : null,
        'statusHistory': [
          ...existingOrder.statusHistory.map((item) => item.toMap()),
          entry.toMap(),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final userBody = _bodyForStatus(normalizedStatus, nextOrder);
      if (nextOrder.userId.isNotEmpty) {
        await NotificationRepository.sendNotification(
          audience: 'user',
          recipientId: nextOrder.userId,
          title: 'Custom order update: ${nextOrder.displayStatus}',
          body: userBody,
          category: 'custom_order',
          entityType: 'custom_order',
          entityId: nextOrder.id,
        );
      }
      await NotificationRepository.sendNotification(
        audience: 'admin',
        recipientId: '',
        title: 'Custom order updated',
        body:
            '${nextOrder.name} is now marked ${nextOrder.displayStatus.toLowerCase()}.',
        category: 'custom_order',
        entityType: 'custom_order',
        entityId: nextOrder.id,
      );
      await SystemEmailService.queueEmail(
        to: nextOrder.email,
        from: SystemEmailService.noReplyAddress,
        subject: 'Custom order update: ${nextOrder.displayStatus}',
        body: userBody,
        type: 'custom_order_update',
        relatedEntityId: nextOrder.id,
        relatedEntityType: 'custom_order',
      );
    } catch (e) {
      debugPrint('CustomOrderRepository.reviewCustomOrder error: $e');
      rethrow;
    }
  }

  static Future<void> respondToQuote(
    CustomOrderModel order, {
    required bool confirmed,
  }) async {
    final nextStatus = confirmed ? 'confirmed' : 'rejected';
    final nextOrder = CustomOrderModel(
      id: order.id,
      userId: order.userId,
      name: order.name,
      email: order.email,
      phone: order.phone,
      productType: order.productType,
      size: order.size,
      glazePreference: order.glazePreference,
      glazeFinish: order.glazeFinish,
      quantity: order.quantity,
      specialNotes: order.specialNotes,
      inspirationImageUrl: order.inspirationImageUrl,
      status: nextStatus,
      quotedPrice: order.quotedPrice,
      adminNotes: order.adminNotes,
      proposedCreationDate: order.proposedCreationDate,
      razorpayOrderId: order.razorpayOrderId,
      razorpayPaymentId: order.razorpayPaymentId,
      paymentStatus: order.paymentStatus,
      cleanupAfter: confirmed
          ? null
          : DateTime.now().add(const Duration(days: 30)),
      createdAt: order.createdAt,
      updatedAt: DateTime.now(),
      statusHistory: order.statusHistory,
    );
    await reviewCustomOrder(
      nextOrder,
      note: confirmed
          ? 'Customer confirmed the quote.'
          : 'Customer rejected the quote.',
    );
  }

  static Future<void> cleanupRejectedOrders() async {
    try {
      final snap = await _db
          .collection('custom_orders')
          .where('status', isEqualTo: 'rejected')
          .get();

      final now = DateTime.now();
      for (final doc in snap.docs) {
        final order = CustomOrderModel.fromDoc(doc);
        final cleanupAfter = order.cleanupAfter;
        if (cleanupAfter == null || cleanupAfter.isAfter(now)) {
          continue;
        }

        if (order.inspirationImageUrl.isNotEmpty) {
          await _media.deletePublicUrls([order.inspirationImageUrl]);
        }

        if (order.userId.isNotEmpty) {
          await NotificationRepository.sendNotification(
            audience: 'user',
            recipientId: order.userId,
            title: 'Rejected custom order removed',
            body:
                'The rejected custom order ${order.id.substring(0, 8).toUpperCase()} has been removed after 30 days.',
            category: 'custom_order',
            entityType: 'custom_order',
            entityId: order.id,
          );
        }
        await NotificationRepository.sendNotification(
          audience: 'admin',
          recipientId: '',
          title: 'Rejected custom order removed',
          body:
              'Old rejected custom order ${order.id} was cleaned up automatically.',
          category: 'custom_order',
          entityType: 'custom_order',
          entityId: order.id,
        );
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('CustomOrderRepository.cleanupRejectedOrders error: $e');
    }
  }

  static String _bodyForStatus(String status, CustomOrderModel order) {
    switch (status) {
      case 'in_review':
        return 'Your request is now set to review by the studio team.';
      case 'quoted':
        return 'A quote of ₹${order.quotedPrice.toStringAsFixed(0)} is ready. You can now confirm or reject it from your account.';
      case 'confirmed':
        return 'Your custom order has been confirmed and will move into production.';
      case 'rejected':
        return 'This custom order was rejected and will be removed from the system after 30 days.';
      case 'in_production':
        return 'The studio has started crafting your custom order.';
      case 'ready_to_dispatch':
        return 'Your custom order is packed and ready to dispatch.';
      case 'in_transit':
        return 'Your custom order is in transit. Delivery tracking is running in demo mode.';
      case 'delivered':
        return 'Your custom order has been marked delivered.';
      default:
        return 'Your custom order has been updated.';
    }
  }
}
