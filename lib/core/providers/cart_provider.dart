import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/product.dart';
import '../services/local_session_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final bool isExclusive;
  final String? sku;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.isExclusive = false,
    this.sku,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      isExclusive: isExclusive,
      sku: sku,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'isExclusive': isExclusive,
      'sku': sku,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      isExclusive: map['isExclusive'] as bool? ?? false,
      sku: map['sku'] as String?,
    );
  }
}

class CartProvider with ChangeNotifier {
  CartProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _loadGuestCart();
      } else {
        _load(user.uid);
      }
    });
  }

  final Map<String, CartItem> _items = {};
  late final StreamSubscription<User?> _authSubscription;

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(dynamic product, {int quantity = 1}) {
    if (product is Product) {
      if (_items.containsKey(product.id)) {
        _items.update(
          product.id,
          (existing) =>
              existing.copyWith(quantity: existing.quantity + quantity),
        );
      } else {
        _items.putIfAbsent(
          product.id,
          () => CartItem(
            id: product.id,
            name: product.title,
            price: product.sellingPrice,
            imageUrl: product.primaryImage,
            quantity: quantity,
            isExclusive: false,
            sku: product.sku,
          ),
        );
      }
    } else if (product is ExclusiveProduct) {
      if (_items.containsKey(product.id)) {
        _items.update(
          product.id,
          (existing) =>
              existing.copyWith(quantity: existing.quantity + quantity),
        );
      } else {
        _items.putIfAbsent(
          product.id,
          () => CartItem(
            id: product.id,
            name: product.title,
            price: product.sellingPrice,
            imageUrl: product.primaryImage,
            quantity: quantity,
            isExclusive: true,
            sku: product.sku,
          ),
        );
      }
    }
    notifyListeners();
    _persist();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    _persist();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => existing.copyWith(quantity: existing.quantity - 1),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
    _persist();
  }

  void incrementQuantity(String productId) {
    if (!_items.containsKey(productId)) return;
    _items.update(
      productId,
      (existing) => existing.copyWith(quantity: existing.quantity + 1),
    );
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  Future<void> _load(String uid) async {
    try {
      final guestItems = await LocalSessionService.readGuestCart();
      final doc = await FirebaseFirestore.instance
          .collection('user_carts')
          .doc(uid)
          .get();
      final rawItems = (doc.data()?['items'] as List?) ?? const [];

      _items.clear();
      for (final item in rawItems.whereType<Map>()) {
        final cartItem = CartItem.fromMap(Map<String, dynamic>.from(item));
        if (cartItem.id.isNotEmpty) {
          _items[cartItem.id] = cartItem;
        }
      }

      for (final item in guestItems) {
        final guestItem = CartItem.fromMap(item);
        if (guestItem.id.isEmpty) continue;
        if (_items.containsKey(guestItem.id)) {
          _items.update(
            guestItem.id,
            (existing) => existing.copyWith(
              quantity: existing.quantity + guestItem.quantity,
            ),
          );
        } else {
          _items[guestItem.id] = guestItem;
        }
      }

      if (guestItems.isNotEmpty) {
        await _persist();
        await LocalSessionService.clearGuestCart();
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await LocalSessionService.writeGuestCart(
        _items.values.map((item) => item.toMap()).toList(),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('user_carts')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'items': _items.values.map((item) => item.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _loadGuestCart() async {
    final guestItems = await LocalSessionService.readGuestCart();
    _items
      ..clear()
      ..addEntries(
        guestItems
            .map(CartItem.fromMap)
            .where((item) => item.id.isNotEmpty)
            .map((item) => MapEntry(item.id, item)),
      );
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
