import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/catalog/repositories/category_repository.dart';
import '../../../models/product.dart';
import 'product_detail/product_detail_content.dart';
import 'product_detail/product_detail_models.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({super.key, this.product, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  String? get _resolvedProductId => widget.productId ?? widget.product?.id;

  @override
  Widget build(BuildContext context) {
    final productId = _resolvedProductId;
    if (productId == null || productId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Product not found')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = ProductDetailData.fromSnapshot(
          snapshot.data,
          fallback: widget.product,
        );

        if (snapshot.connectionState == ConnectionState.waiting &&
            data == null) {
          return const ProductDetailLoadingView();
        }

        if (data == null) {
          return ProductDetailErrorView(productId: productId);
        }

        if (_selectedImageIndex >= data.images.length) {
          _selectedImageIndex = 0;
        }

        return FutureBuilder<ProductCategory?>(
          future: data.categoryId.isEmpty
              ? Future.value(null)
              : CategoryRepository.getCategory(data.categoryId),
          builder: (context, categorySnapshot) {
            return ProductDetailContent(
              data: data,
              category: categorySnapshot.data,
              selectedImageIndex: _selectedImageIndex,
              quantity: _quantity,
              onImageSelected: (index) {
                setState(() => _selectedImageIndex = index);
              },
              onDecreaseQuantity: () {
                if (_quantity > 1) setState(() => _quantity -= 1);
              },
              onIncreaseQuantity: () {
                setState(() => _quantity += 1);
              },
              onAddToCart: () => _addToCart(data),
              onBuyNow: () {
                _addToCart(data);
                Navigator.pushNamed(context, Routes.cart);
              },
            );
          },
        );
      },
    );
  }

  void _addToCart(ProductDetailData data) {
    context.read<CartProvider>().addItem(
      data.toCartProduct(),
      quantity: _quantity,
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: AppTheme.terracotta,
          content: Text(
            '${data.title} added to cart',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.white),
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: AppTheme.white,
            onPressed: () => Navigator.pushNamed(context, Routes.cart),
          ),
        ),
      );
  }
}
