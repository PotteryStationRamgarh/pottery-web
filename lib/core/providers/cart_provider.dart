import 'package:flutter/foundation.dart';
import '../../models/product.dart';

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
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

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
          (existing) => existing.copyWith(quantity: existing.quantity + quantity),
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
          (existing) => existing.copyWith(quantity: existing.quantity + quantity),
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
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
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
  }

  void incrementQuantity(String productId) {
    if (!_items.containsKey(productId)) return;
    _items.update(
      productId,
      (existing) => existing.copyWith(quantity: existing.quantity + 1),
    );
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
