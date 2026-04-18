import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../models/order_model.dart';
import '../home/widgets/nav_bar.dart';
import '../home/home_footer.dart';

/// Shown after a successful order placement.
/// Takes order ID as argument: Navigator.pushReplacementNamed(context, Routes.orderConfirmation, arguments: order.id)
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orderId =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    if (orderId.isNotEmpty) {
      _loadOrder(orderId);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOrder(String orderId) async {
    try {
      final orders = await OrderRepository.getAllOrders();
      final order = orders.cast<OrderModel?>().firstWhere(
        (o) => o?.id == orderId,
        orElse: () => null,
      );
      if (mounted) setState(() { _order = order; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final shortId = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : 24,
                    vertical: 60,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          // ─── Success Icon ───────────────────────
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.successGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.successGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 52,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ─── Heading ────────────────────────────
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Column(
                              children: [
                                Text(
                                  'Order Confirmed!',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Thank you for choosing Pottery Station Ramgarh.\nYour handcrafted pieces are being prepared.',
                                  style: GoogleFonts.jost(
                                    fontSize: 15,
                                    color: AppTheme.textLight,
                                    height: 1.7,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ─── Order ID Card ───────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Order ID',
                                  value: '#$shortId',
                                  highlight: true,
                                ),
                                const Divider(height: 24),
                                _DetailRow(
                                  label: 'Status',
                                  value: 'Pending Confirmation',
                                  icon: Icons.hourglass_top_outlined,
                                ),
                                const SizedBox(height: 12),
                                if (_isLoading)
                                  const LinearProgressIndicator()
                                else if (_order?.estimatedDelivery != null) ...[
                                  const Divider(height: 24),
                                  _DetailRow(
                                    label: 'Estimated Delivery',
                                    value: _formatDate(
                                      _order!.estimatedDelivery!,
                                    ),
                                    icon: Icons.local_shipping_outlined,
                                  ),
                                ],
                                if (_order?.items.isNotEmpty == true) ...[
                                  const Divider(height: 24),
                                  Text(
                                    'Items (${_order!.items.length})',
                                    style: GoogleFonts.jost(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textLight,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._order!.items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: GoogleFonts.jost(
                                                fontSize: 13,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '×${item.qty}  ₹${(item.sellingPrice * item.qty).toInt()}',
                                            style: GoogleFonts.jost(
                                              fontSize: 13,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total',
                                        style: GoogleFonts.jost(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        '₹${_order!.totalAmount.toInt()}',
                                        style: GoogleFonts.jost(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.terracotta,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ─── Demo Payment Note ─────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Payment collection is in demo mode. Our team will reach out for payment details.',
                                    style: GoogleFonts.jost(
                                      fontSize: 12,
                                      color: Colors.amber[800],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ─── CTAs ────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    Routes.customerHome,
                                    (r) => false,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: AppTheme.primaryBrown.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Continue Shopping',
                                    style: GoogleFonts.jost(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBrown,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    Routes.myAccount,
                                    (r) => false,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.terracotta,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'View My Orders',
                                    style: GoogleFonts.jost(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final IconData? icon;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppTheme.textLight),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.jost(fontSize: 13, color: AppTheme.textLight),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.jost(
            fontSize: highlight ? 16 : 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? AppTheme.primaryBrown : AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
