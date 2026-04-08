import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../../models/product.dart';
import '../../models/exhibition.dart';
import '../utils/storefront_filters.dart';
import 'exhibition_repository.dart';

/// Single source of truth for all data loaded by the customer home screen.
/// CustomerHomeScreen calls HomeRepository.fetchAll() — no widget fetches
/// Firestore independently.
class HomeRepository {
  HomeRepository._();

  static final _db = FirebaseFirestore.instance;
  static const _col = 'products';

  static Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    try {
      final snap = await _db
          .collection(_col)
          .where('isActive', isEqualTo: true)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );
      return snap.docs
          .map(Product.fromDoc)
          .where(StorefrontFilters.showProduct)
          .toList();
    } catch (e) {
      debugPrint('HomeRepository.getProducts error: $e');
      return [];
    }
  }

  static Future<List<ExclusiveProduct>> getExclusiveProducts({
    bool forceRefresh = false,
  }) async {
    try {
      final snap = await _db
          .collection('exclusive_products')
          .orderBy('order')
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );
      return snap.docs
          .map(ExclusiveProduct.fromDoc)
          .where(StorefrontFilters.showExclusiveProduct)
          .toList();
    } catch (e) {
      debugPrint('HomeRepository.getExclusiveProducts error: $e');
      return [];
    }
  }

  /// Fetches all three data sources in parallel.
  static Future<HomeData> fetchAll({bool forceRefresh = false}) async {
    final results = await Future.wait([
      getProducts(forceRefresh: forceRefresh),
      getExclusiveProducts(forceRefresh: forceRefresh),
      ExhibitionRepository.getActive(forceRefresh: forceRefresh),
    ]);

    final products = results[0] as List<Product>;
    final exclusiveProducts = results[1] as List<ExclusiveProduct>;

    _fisherYatesShuffle(products);
    _fisherYatesShuffle(exclusiveProducts);

    return HomeData(
      products: products,
      exclusiveProducts: exclusiveProducts,
      activeExhibition: results[2] as Exhibition,
    );
  }

  static void _fisherYatesShuffle<T>(List<T> items) {
    final random = Random();
    for (var i = items.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = items[i];
      items[i] = items[j];
      items[j] = temp;
    }
  }
}

class HomeData {
  final List<Product> products;
  final List<ExclusiveProduct> exclusiveProducts;
  final Exhibition activeExhibition;

  const HomeData({
    required this.products,
    required this.exclusiveProducts,
    required this.activeExhibition,
  });
}
