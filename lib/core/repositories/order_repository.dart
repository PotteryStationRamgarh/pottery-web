import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/order_model.dart';

class OrderRepository {
  OrderRepository._();

  static final _db = FirebaseFirestore.instance;

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
}
