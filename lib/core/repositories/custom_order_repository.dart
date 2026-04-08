import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/media_service.dart';
import '../../models/custom_order_model.dart';

class CustomOrderRepository {
  CustomOrderRepository._();

  static final _db = FirebaseFirestore.instance;
  static final _media = MediaService();

  static Future<void> submitCustomOrder(CustomOrderModel order) async {
    try {
      final docRef = order.id.isEmpty
          ? _db.collection('custom_orders').doc()
          : _db.collection('custom_orders').doc(order.id);

      await docRef.set(order.toMap(), SetOptions(merge: true));
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
      final docRef = order.id.isEmpty
          ? _db.collection('custom_orders').doc()
          : _db.collection('custom_orders').doc(order.id);

      final payload = {...order.toMap()};
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

  static Future<void> updateCustomOrder(CustomOrderModel order) async {
    try {
      await _db.collection('custom_orders').doc(order.id).set(
        {
          ...order.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('CustomOrderRepository.updateCustomOrder error: $e');
      rethrow;
    }
  }
}
