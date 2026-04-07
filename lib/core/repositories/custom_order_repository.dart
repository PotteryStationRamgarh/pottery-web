import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/custom_order_model.dart';

class CustomOrderRepository {
  CustomOrderRepository._();

  static final _db = FirebaseFirestore.instance;

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
}
