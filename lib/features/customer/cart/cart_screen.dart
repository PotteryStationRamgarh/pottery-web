import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_gate_service.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/repositories/address_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../models/address_model.dart';
import '../../../models/order_model.dart';
import '../../../app/routes.dart';
import '../home/home_footer.dart';
import '../home/widgets/nav_bar.dart';
import 'widgets/address_selection_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<AddressModel> _savedAddresses = [];
  String? _selectedAddressId;
  bool _isLoadingAddresses = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingAddresses = true);
    try {
      final addresses = await AddressRepository.getAddressesByUser(user.uid);
      setState(() {
        _savedAddresses = addresses;
        if (addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
          _selectedAddressId = defaultAddr.id;
        }
      });
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : 20,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Collection",
                        style: AppTheme.serifHeadingLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${cart.itemCount} items in your curation",
                        style: GoogleFonts.jost(
                          color: AppTheme.textLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (items.isEmpty)
                        _buildEmptyState()
                      else if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildCartItems(items)),
                            const SizedBox(width: 60),
                            Expanded(flex: 2, child: _buildCheckoutPanel(cart)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildCartItems(items),
                            const SizedBox(height: 48),
                            _buildCheckoutPanel(cart),
                          ],
                        ),
                    ],
                  ),
                ),
                const HomeFooter(),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: AppTheme.divider,
          ),
          const SizedBox(height: 24),
          Text(
            "Your basket is empty",
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Explore our collections and find something unique.",
            style: GoogleFonts.jost(color: AppTheme.textLight),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 240,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, Routes.customerHome),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "CONTINUE SHOPPING",
                style: GoogleFonts.jost(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(List<CartItem> items) {
    return Column(children: [...items.map((item) => _buildCartItem(item))]);
  }

  Widget _buildCartItem(CartItem item) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        item.isExclusive ? Routes.exclusiveDetail : Routes.productDetail,
        arguments: item.id,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 78,
                height: 78,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 78,
                  height: 78,
                  color: AppTheme.divider.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (item.isExclusive) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "EXCLUSIVE PIECE",
                        style: GoogleFonts.jost(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.terracotta,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    "₹${item.price.toInt()}",
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppTheme.textLight,
                  ),
                  onPressed: () {
                    context.read<CartProvider>().removeItem(item.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 40),
                _buildQtyStepper(item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyStepper(CartItem item) {
    final cart = context.read<CartProvider>();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(Icons.remove, () {
            cart.removeSingleItem(item.id);
          }),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              "${item.quantity}",
              style: GoogleFonts.jost(fontWeight: FontWeight.w600),
            ),
          ),
          _stepperButton(Icons.add, () {
            cart.incrementQuantity(item.id);
          }),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 14, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildCheckoutPanel(CartProvider cart) {
    double subtotal = cart.totalAmount;
    double delivery = 0;
    double total = subtotal + delivery;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Acquisition Details", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 24),
          _buildAddressSection(),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 32),
          _buildSummaryRow("Subtotal", "₹${subtotal.toInt()}"),
          _buildSummaryRow(
            "Delivery Charges",
            delivery == 0 ? "FREE" : "₹${delivery.toInt()}",
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildSummaryRow("Total", "₹${total.toInt()}", isTotal: true),
          const SizedBox(height: 40),
          _buildCompletePurchaseButton(),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  "Secured by Pottery Station",
                  style: GoogleFonts.jost(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sign in to continue",
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Your cart is saved locally. Sign in to attach it to your account and complete the order.",
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  AuthGateService.requireLogin(context, routeName: Routes.cart),
              child: const Text('SIGN IN TO CHECK OUT'),
            ),
          ),
        ],
      );
    }

    if (_isLoadingAddresses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppTheme.terracotta),
        ),
      );
    }

    if (_savedAddresses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shipping Address",
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You have no saved addresses yet.',
            style: GoogleFonts.jost(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                Routes.savedAddresses,
              ).then((_) => _loadAddresses()),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Add Delivery Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Select Shipping Address",
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
                letterSpacing: 1,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                Routes.savedAddresses,
              ).then((_) => _loadAddresses()),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._savedAddresses.map(
          (addr) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AddressSelectionCard(
              address: addr,
              isSelected: _selectedAddressId == addr.id,
              onTap: () => setState(() => _selectedAddressId = addr.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AddAddressCard(
          onTap: () => Navigator.pushNamed(
            context,
            Routes.savedAddresses,
          ).then((_) => _loadAddresses()),
        ),
      ],
    );
  }


  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )
                : GoogleFonts.jost(color: AppTheme.textLight),
          ),
          Text(
            value,
            style: isTotal
                ? GoogleFonts.jost(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.terracotta,
                  )
                : GoogleFonts.jost(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _handleCompletePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isPlacingOrder ? "PLACING ORDER..." : "COMPLETE PURCHASE",
          style: GoogleFonts.jost(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompletePurchase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AuthGateService.requireLogin(context, routeName: Routes.cart);
      return;
    }

    if (_selectedAddressId == null || _selectedAddressId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or add a shipping address first.'),
        ),
      );
      return;
    }

    final address = _savedAddresses.cast<AddressModel?>().firstWhere(
      (item) => item?.id == _selectedAddressId,
      orElse: () => null,
    );
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected address could not be loaded.'),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final items = cart.items.values
        .map(
          (item) => OrderItem(
            productId: item.id,
            title: item.name,
            imageUrl: item.imageUrl,
            qty: item.quantity,
            sellingPrice: item.price,
            sku: item.sku ?? '',
            isExclusive: item.isExclusive,
          ),
        )
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final order = await OrderRepository.createOrder(
        userId: user.uid,
        customerEmail: user.email ?? '',
        customerPhone: address.phone,
        address: address,
        items: items,
        totalAmount: cart.totalAmount,
      );

      cart.clear();

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        Routes.orderConfirmation,
        arguments: order.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to place order: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}
