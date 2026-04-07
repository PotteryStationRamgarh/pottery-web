import 'package:flutter/material.dart';
import '../features/admin/admin_layout.dart';
import '../app/routes.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/signin/signin_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/verify_email/verify_email_screen.dart';
import '../features/auth/forgot_password/forgot_password_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/customer/home/customer_home_screen.dart';
import '../features/customer/gallery/gallery_screen.dart';
import '../features/customer/products/customer_products_screen.dart';
import '../models/product.dart';
import '../features/admin/profile/admin_profile_page.dart';
import '../features/customer/loading/customer_loading_screen.dart';
import '../features/customer/exclusive/exclusive_detail_screen.dart';
import '../features/customer/exclusive/exclusive_list_screen.dart';
import '../features/customer/categories/customer_categories_grid_page.dart';
import '../features/customer/products/product_detail_screen.dart';
import '../features/customer/cart/cart_screen.dart';
import '../features/customer/account/my_account_screen.dart';
import '../features/customer/account/saved_addresses_screen.dart';
import '../features/customer/orders/custom_order_screen.dart';

/// Root of the entire app.
/// All screens are registered here as named routes.
/// Think of this as the "map" of the app —
/// every screen has an address (route) defined here.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pottery Station Ramgarh',

      // All colors, fonts, button styles come from AppTheme
      // No screen needs to define its own theme
      theme: AppTheme.themeData,

      // App always starts at splash —
      // splash decides where to go next based on auth + maintenance
      initialRoute: Routes.splash,

      routes: {
        // First screen — checks maintenance, auth, role
        Routes.splash: (context) => const SplashScreen(),

        // Auth flow — sign in, sign up, verify email, loading
        Routes.signin: (context) => const SigninScreen(),
        Routes.signup: (context) => const SignupScreen(),
        Routes.verifyEmail: (context) => const VerifyEmailScreen(),
        Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
        Routes.customerLoading: (_) => const CustomerLoadingScreen(),

        // Shown when admin sets maintenanceMode: true in Firestore
        // Admin bypasses this and goes straight to dashboard
        Routes.maintenance: (context) => const MaintenanceScreen(),

        // Main screen for logged-in customers
        Routes.customerHome: (context) => const CustomerHomeScreen(),

        // Browse collections
        Routes.categories: (context) => const CustomerCategoriesGridPage(),

        // Browse products by category — arguments: {categoryId, categoryName}
        Routes.products: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;
          return CustomerProductsScreen(
            categoryId: args?['categoryId'] ?? '',
            categoryName: args?['categoryName'] ?? 'Products',
          );
        },

        // Gallery page — arguments: Product
        Routes.gallery: (context) {
          final product = ModalRoute.of(context)!.settings.arguments as Product;
          return GalleryScreen(product: product);
        },

        // Dedicated Exclusive Detail Page — arguments: ExclusiveProduct
        Routes.exclusiveDetail: (context) {
          final product =
              ModalRoute.of(context)!.settings.arguments as ExclusiveProduct;
          return ExclusiveDetailScreen(product: product);
        },

        // New route for all Exclusive products
        Routes.exclusiveList: (context) => const ExclusiveListScreen(),

        // Ecommerce screens
        Routes.productDetail: (context) => const ProductDetailScreen(),
        Routes.cart: (context) => const CartScreen(),
        Routes.myAccount: (context) => const MyAccountScreen(),
        Routes.savedAddresses: (context) => const SavedAddressesScreen(),
        Routes.customOrder: (context) => const CustomOrderScreen(),

        // Only accessible to users with role: 'admin' in Firestore
        Routes.adminDashboard: (context) => const AdminLayout(),

        // Admin Profile Page
        Routes.profile: (context) => const AdminProfilePage(),
      },
    );
  }
}
