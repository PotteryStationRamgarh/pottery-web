import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/order_model.dart';
import '../home/widgets/nav_bar.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  int _selectedTabIndex = 2; // Default to Order History
  List<OrderModel> _orders = [];
  bool _isLoadingOrders = true;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (_user == null) {
      if (mounted) setState(() => _isLoadingOrders = false);
      return;
    }

    try {
      final orders = await OrderRepository.getOrdersByUser(_user.uid);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.signin, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
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
                  child: Row(
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
                              _buildMobileTabSelector(),
                              const SizedBox(height: 48),
                            ],
                            _buildActiveView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sidebarItem(0, "My Profile", Icons.person_outline),
          _sidebarItem(1, "Delivery Addresses", Icons.location_on_outlined),
          _sidebarItem(2, "Order History", Icons.shopping_bag_outlined),
          _sidebarItem(3, "Returns", Icons.replay_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(),
          ),
          _sidebarItem(4, "Logout", Icons.logout, isLogout: true),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String label, IconData icon, {bool isLogout = false}) {
    bool isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        if (isLogout) {
          _handleLogout();
        } else if (index == 1) {
          Navigator.pushNamed(context, Routes.savedAddresses);
        } else {
          setState(() => _selectedTabIndex = index);
        }
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
            Text(
              label,
              style: GoogleFonts.jost(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isLogout
                    ? AppTheme.errorRed
                    : (isSelected ? AppTheme.terracotta : AppTheme.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _mobileTabItem(0, "Profile"),
          _mobileTabItem(1, "Addresses"),
          _mobileTabItem(2, "History"),
          _mobileTabItem(3, "Returns"),
        ],
      ),
    );
  }

  Widget _mobileTabItem(int index, String label) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, Routes.savedAddresses);
        } else {
          setState(() => _selectedTabIndex = index);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.terracotta : Colors.transparent,
          border: Border.all(color: isSelected ? AppTheme.terracotta : AppTheme.divider),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileView();
      case 2:
        return _buildOrderHistory();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(Icons.auto_stories_outlined, size: 60, color: AppTheme.divider),
              const SizedBox(height: 24),
              Text(
                "Experience Under Curation",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We are refining this section to serve you better.",
                style: GoogleFonts.jost(color: AppTheme.textLight),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Account Settings", style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileField("Email Address", _user?.email ?? "Not available"),
              const SizedBox(height: 32),
              _profileField("Account Type", "Customer"),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Change password
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.terracotta,
                    side: const BorderSide(color: AppTheme.terracotta),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    "CHANGE PASSWORD",
                    style: GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
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

  Widget _buildOrderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Past Acquisitions", style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 48),
        if (_isLoadingOrders)
          const Center(child: CircularProgressIndicator(color: AppTheme.terracotta))
        else if (_orders.isEmpty)
          _buildEmptyHistory()
        else
          ..._orders.map((order) => _buildOrderCard(order)).toList(),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.divider),
          const SizedBox(height: 24),
          Text(
            "No orders yet",
            style: GoogleFonts.playfairDisplay(fontSize: 20, color: AppTheme.textLight),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.products),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("EXPLORE SHOP", style: GoogleFonts.jost(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateStr = order.createdAt != null ? DateFormat('MMM dd, yyyy').format(order.createdAt!) : 'Recent';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                    "Order #${order.id.toUpperCase().substring(0, 8)}",
                    style: GoogleFonts.jost(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1),
                  ),
                  Text(
                    "Placed on $dateStr",
                    style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
              _buildStatusBadge(order.orderStatus),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: order.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                          image: DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Total Amount",
                    style: GoogleFonts.jost(fontSize: 11, color: AppTheme.textLight, letterSpacing: 0.5),
                  ),
                  Text(
                    "₹${order.totalAmount.toInt()}",
                    style: GoogleFonts.jost(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.terracotta,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "View details for delivery estimation",
                style: GoogleFonts.jost(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
              _smallButton("View Details", isPrimary: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        color = Colors.green[700]!;
        break;
      case 'SHIPPED':
      case 'IN TRANSIT':
        color = Colors.orange[700]!;
        break;
      case 'CANCELLED':
        color = AppTheme.errorRed;
        break;
      default:
        color = Colors.blue[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.jost(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }

  Widget _smallButton(String label, {required bool isPrimary}) {
    return InkWell(
      onTap: () {
        // TODO: Action
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.terracotta : Colors.white,
          border: Border.all(color: AppTheme.terracotta),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isPrimary ? Colors.white : AppTheme.terracotta,
          ),
        ),
      ),
    );
  }
}
