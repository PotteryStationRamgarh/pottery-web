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
  static const _col = 'products';
  static const _exclusiveCol = 'exclusive_products';

  static Future<List<Product>> getProducts() async {
    try {
      final snap = await _db
          .collection(_col)
          .where('isActive', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
      return snap.docs.map(Product.fromDoc).toList();
    } catch (e) {
      debugPrint('HomeRepository.getProducts error: $e');
      return [];
    }
  }

  static Future<List<ExclusiveProduct>> getExclusiveProducts() async {
    try {
      final snap = await _db.collection('exclusive_products').orderBy('order').get(const GetOptions(source: Source.server));
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

    final products = results[0] as List<Product>;
    final exclusiveProducts = results[1] as List<ExclusiveProduct>;
    
    // Shuffle for random order for customers
    products.shuffle();
    exclusiveProducts.shuffle();

    return HomeData(
      products:          products,
      exclusiveProducts: exclusiveProducts,
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