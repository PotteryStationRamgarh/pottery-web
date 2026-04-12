import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/repositories/custom_order_repository.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/support_repository.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_notification.dart';
import '../../../models/custom_order_model.dart';
import '../../../models/order_model.dart';
import '../../../models/support_message.dart';
import '../home/home_footer.dart';
import '../home/widgets/nav_bar.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _phoneController = TextEditingController();

  int _selectedTabIndex = 1;
  bool _isLoading = true;
  bool _isSubmittingSupport = false;

  String _supportType = 'support';

  List<OrderModel> _orders = [];
  List<CustomOrderModel> _customOrders = [];
  List<AppNotification> _notifications = [];
  List<SupportMessage> _supportRequests = [];
  Map<String, dynamic> _profile = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _orderIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        OrderRepository.getOrdersByUser(_user.uid),
        CustomOrderRepository.getCustomOrdersByUser(_user.uid),
        NotificationRepository.getForUser(_user.uid),
        SupportRepository.getForUser(_user.uid),
        FirebaseService.getUserProfile(_user.uid),
      ]);

      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<OrderModel>;
        _customOrders = results[1] as List<CustomOrderModel>;
        _notifications = results[2] as List<AppNotification>;
        _supportRequests = results[3] as List<SupportMessage>;
        _profile = results[4] as Map<String, dynamic>;
        _phoneController.text = (_profile['phoneNumber'] as String? ?? '')
            .trim();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.customerHome,
      (route) => false,
    );
  }

  Future<void> _verifyPhoneDummy() async {
    if (_user == null) return;
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number first.')),
      );
      return;
    }

    await FirebaseService.updateUserProfile(_user.uid, {
      'phoneNumber': phone,
      'phoneVerificationStatus': 'verified_dummy',
      'phoneVerifiedAt': DateTime.now(),
    });
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Phone marked verified in demo mode. Web OTP is not wired yet.',
        ),
      ),
    );
  }

  Future<void> _submitSupportRequest() async {
    if (_user == null) return;
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add both a subject and a message.')),
      );
      return;
    }

    setState(() => _isSubmittingSupport = true);
    try {
      await SupportRepository.submitRequest(
        SupportMessage(
          id: '',
          userId: _user.uid,
          name: (_profile['displayName'] as String? ?? '').trim().isEmpty
              ? (_user.email ?? 'Customer')
              : (_profile['displayName'] as String? ?? '').trim(),
          email: _user.email ?? '',
          phone: _phoneController.text.trim(),
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          type: _supportType,
          status: 'open',
          orderId: _orderIdController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      _subjectController.clear();
      _messageController.clear();
      _orderIdController.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to submit request: $e')));
    } finally {
      if (mounted) setState(() => _isSubmittingSupport = false);
    }
  }

  Future<void> _respondToQuote(CustomOrderModel order, bool confirm) async {
    await CustomOrderRepository.respondToQuote(order, confirmed: confirm);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          confirm
              ? 'Quote confirmed. The order will move into production.'
              : 'Quote rejected. The request will auto-clean after 30 days.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    horizontal: isDesktop ? 80 : 20,
                    vertical: 40,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.terracotta,
                          ),
                        )
                      : _user == null
                      ? _buildLoggedOutView()
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isDesktop) ...[
                              _buildSidebar(),
                              const SizedBox(width: 80),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isDesktop) ...[
                                    _buildMobileTabs(),
                                    const SizedBox(height: 32),
                                  ],
                                  _buildActiveView(),
                                ],
                              ),
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

  Widget _buildLoggedOutView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Sign in to view your account',
                style: AppTheme.serifHeadingMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Your cart and wishlist stay available while browsing. Sign in when you want to place orders, manage addresses, or track updates.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, Routes.signin),
                child: const Text('Go To Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sidebarItem(0, 'My Profile', Icons.person_outline),
          _sidebarItem(1, 'Orders', Icons.shopping_bag_outlined),
          _sidebarItem(2, 'Notifications', Icons.notifications_none),
          _sidebarItem(3, 'Support & Returns', Icons.support_agent_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(),
          ),
          _sidebarItem(4, 'Delivery Addresses', Icons.location_on_outlined),
          _sidebarItem(5, 'Logout', Icons.logout, isLogout: true),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    int index,
    String label,
    IconData icon, {
    bool isLogout = false,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        if (isLogout) {
          _handleLogout();
          return;
        }
        if (index == 4) {
          Navigator.pushNamed(
            context,
            Routes.savedAddresses,
          ).then((_) => _load());
          return;
        }
        setState(() => _selectedTabIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isLogout
                  ? AppTheme.errorRed
                  : (isSelected ? AppTheme.terracotta : AppTheme.textLight),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.jost(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isLogout
                      ? AppTheme.errorRed
                      : (isSelected ? AppTheme.terracotta : AppTheme.textDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabs() {
    final tabs = const <MapEntry<int, String>>[
      MapEntry(0, 'Profile'),
      MapEntry(1, 'Orders'),
      MapEntry(2, 'Notifications'),
      MapEntry(3, 'Support'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map(
              (tab) => GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = tab.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == tab.key
                        ? AppTheme.terracotta
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedTabIndex == tab.key
                          ? AppTheme.terracotta
                          : AppTheme.divider,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    tab.value,
                    style: GoogleFonts.jost(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == tab.key
                          ? Colors.white
                          : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActiveView() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileView();
      case 1:
        return _buildOrdersView();
      case 2:
        return _buildNotificationsView();
      case 3:
        return _buildSupportView();
      default:
        return _buildProfileView();
    }
  }

  Widget _buildProfileView() {
    final phoneStatus =
        (_profile['phoneVerificationStatus'] as String? ?? 'not_started');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings', style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileField('Email Address', _user?.email ?? 'Not available'),
              const SizedBox(height: 24),
              Text('Phone Verification', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                phoneStatus == 'verified_dummy'
                    ? 'Verified in demo mode'
                    : 'Web OTP is not wired yet, so verification runs in dummy mode.',
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: AppTheme.inputDecoration(label: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _verifyPhoneDummy,
                child: const Text('VERIFY PHONE (DEMO)'),
              ),
              const SizedBox(height: 24),
              _profileField(
                'Saved Addresses',
                'Manage Home, Office, Work, and Studio addresses from Addresses.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Orders & Custom Work', style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 32),
        if (_orders.isEmpty && _customOrders.isEmpty) _buildEmptyOrders(),
        if (_orders.isNotEmpty) ...[
          Text('Storefront Orders', style: AppTheme.headingMedium),
          const SizedBox(height: 16),
          ..._orders.map(_buildOrderCard),
          const SizedBox(height: 24),
        ],
        if (_customOrders.isNotEmpty) ...[
          Text('Custom Orders', style: AppTheme.headingMedium),
          const SizedBox(height: 16),
          ..._customOrders.map(_buildCustomOrderCard),
        ],
      ],
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.divider),
          const SizedBox(height: 24),
          Text(
            'No orders yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 220,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.categories),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'EXPLORE SHOP',
                style: GoogleFonts.jost(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.toUpperCase().substring(0, 8)}',
                    style: GoogleFonts.jost(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Placed on $dateStr',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.displayStatus),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: order.items
                .map(
                  (item) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.jost(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.jost(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showOrderDetails(order),
              child: const Text('VIEW DETAILS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomOrderCard(CustomOrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(order.productType, style: AppTheme.headingMedium),
              ),
              _buildStatusBadge(order.displayStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Requested ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
            style: AppTheme.bodySmall,
          ),
          if (order.quotedPrice > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Quoted price: ₹${order.quotedPrice.toStringAsFixed(0)}',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.terracotta),
            ),
          ],
          if (order.adminNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(order.adminNotes, style: AppTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          ...order.statusHistory.reversed
              .take(4)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${DateFormat('dd MMM').format(entry.timestamp)} • ${CustomOrderModel.normalizeStatus(entry.status).replaceAll('_', ' ')} • ${entry.note}',
                    style: AppTheme.bodySmall,
                  ),
                ),
              ),
          if (order.status == 'quoted') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToQuote(order, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.terracotta,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('CONFIRM QUOTE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToQuote(order, false),
                    child: const Text('REJECT QUOTE'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 32),
        if (_notifications.isEmpty)
          Text('No updates yet.', style: AppTheme.bodyLarge)
        else
          ..._notifications.map(
            (notification) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTheme.headingMedium),
                  const SizedBox(height: 8),
                  Text(notification.body, style: AppTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat(
                      'dd MMM yyyy • hh:mm a',
                    ).format(notification.createdAt),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSupportView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Support, Returns & Refunds', style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _supportType,
                decoration: AppTheme.inputDecoration(label: 'Request Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'support',
                    child: Text('Support Query'),
                  ),
                  DropdownMenuItem(
                    value: 'return',
                    child: Text('Return Request'),
                  ),
                  DropdownMenuItem(
                    value: 'refund',
                    child: Text('Refund Request'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _supportType = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: AppTheme.inputDecoration(label: 'Subject'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _orderIdController,
                decoration: AppTheme.inputDecoration(
                  label: 'Order ID (optional)',
                  hint: 'Add an order ID for returns/refunds',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: AppTheme.inputDecoration(label: 'Message'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittingSupport
                      ? null
                      : _submitSupportRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracotta,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isSubmittingSupport ? 'SUBMITTING...' : 'SUBMIT REQUEST',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Recent Requests', style: AppTheme.headingMedium),
        const SizedBox(height: 16),
        if (_supportRequests.isEmpty)
          Text('No support activity yet.', style: AppTheme.bodyLarge)
        else
          ..._supportRequests.map(
            (request) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          request.subject.isEmpty ? 'Request' : request.subject,
                          style: AppTheme.headingMedium,
                        ),
                      ),
                      _buildStatusBadge(request.status.replaceAll('_', ' ')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(request.message, style: AppTheme.bodyMedium),
                  if (request.resolutionNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Resolution: ${request.resolutionNote}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toUpperCase();
    Color color;
    if (normalized.contains('DELIVERED') ||
        normalized.contains('RESOLVED') ||
        normalized.contains('CONFIRMED')) {
      color = Colors.green[700]!;
    } else if (normalized.contains('TRANSIT') ||
        normalized.contains('QUOTED') ||
        normalized.contains('REVIEW')) {
      color = Colors.orange[700]!;
    } else if (normalized.contains('REJECT') ||
        normalized.contains('CANCEL') ||
        normalized.contains('REFUND')) {
      color = AppTheme.errorRed;
    } else {
      color = Colors.blue[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        normalized,
        style: GoogleFonts.jost(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(OrderModel order) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ${order.id.substring(0, 8).toUpperCase()}',
                  style: AppTheme.serifHeadingMedium,
                ),
                const SizedBox(height: 12),
                Text(order.displayStatus, style: AppTheme.bodyLarge),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tracking', style: AppTheme.headingMedium),
                        const SizedBox(height: 8),
                        Text(
                          order.trackingNumber.isEmpty
                              ? 'Tracking will appear once the order moves to in-transit. Delivery is currently a dummy workflow.'
                              : '${order.courierName} • ${order.trackingNumber}',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Text('Timeline', style: AppTheme.headingMedium),
                        const SizedBox(height: 8),
                        ...order.statusTimeline.reversed.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${DateFormat('dd MMM yyyy • hh:mm a').format(entry.createdAt)}\n${entry.title}\n${entry.description}',
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Delivery Address', style: AppTheme.headingMedium),
                        const SizedBox(height: 8),
                        Text(
                          [
                                order.addressSnapshot['name'],
                                order.addressSnapshot['addressLine1'],
                                order.addressSnapshot['addressLine2'],
                                order.addressSnapshot['city'],
                                order.addressSnapshot['state'],
                                order.addressSnapshot['pincode'],
                              ]
                              .whereType<String>()
                              .where((value) => value.trim().isNotEmpty)
                              .join(', '),
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
