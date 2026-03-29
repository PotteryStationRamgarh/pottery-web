import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/product.dart';
import '../../models/exhibition.dart';
import 'exhibition_repository.dart';

/// Single source of truth for all data loaded by the customer home screen.
/// CustomerHomeScreen calls HomeRepository.fetchAll() — no widget fetches
/// Firestore independently.
class HomeRepository {
  HomeRepository._();

  static final _db = FirebaseFirestore.instance;

  static Future<List<Product>> getProducts() async {
    try {
      final snap = await _db.collection('products').orderBy('order').get();
      return snap.docs.map(Product.fromDoc).toList();
    } catch (e) {
      debugPrint('HomeRepository.getProducts error: $e');
      return [];
    }
  }

  static Future<List<ExclusiveProduct>> getExclusiveProducts() async {
    try {
      final snap = await _db.collection('exclusive_products').orderBy('order').get();
      return snap.docs.map(ExclusiveProduct.fromDoc).toList();
    } catch (e) {
      debugPrint('HomeRepository.getExclusiveProducts error: $e');
      return [];
    }
  }

  /// Fetches all three data sources in parallel.
  static Future<HomeData> fetchAll() async {
    final results = await Future.wait([
      getProducts(),
      getExclusiveProducts(),
      ExhibitionRepository.getActive(),
    ]);
    return HomeData(
      products:          results[0] as List<Product>,
      exclusiveProducts: results[1] as List<ExclusiveProduct>,
      activeExhibition:  results[2] as Exhibition,
    );
  }
}

class HomeData {
  final List<Product>          products;
  final List<ExclusiveProduct> exclusiveProducts;
  final Exhibition             activeExhibition;

  const HomeData({
    required this.products,
    required this.exclusiveProducts,
    required this.activeExhibition,
  });
}