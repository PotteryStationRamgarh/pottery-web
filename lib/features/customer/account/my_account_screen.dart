import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes.dart';
import '../home/widgets/nav_bar.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  int _selectedTabIndex = 2; // 0: Profile, 1: Addresses, 2: History, 3: Returns

  final List<Map<String, dynamic>> _dummyOrders = [
    {
      'id': 'ORD-82910',
      'date': 'Mar 24, 2024',
      'price': '₹5,750',
      'status': 'IN TRANSIT',
      'estimate': 'Arriving by Mar 28',
      'images': [
        'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?q=80&w=150&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?q=80&w=150&auto=format&fit=crop',
      ],
    },
    {
      'id': 'ORD-71642',
      'date': 'Feb 12, 2024',
      'price': '₹3,200',
      'status': 'DELIVERED',
      'estimate': 'Delivered on Feb 15',
      'images': [
        'https://images.unsplash.com/photo-1610701596007-11502861dcfa?q=80&w=150&auto=format&fit=crop',
      ],
      'returnable': true,
    },
    {
      'id': 'ORD-65431',
      'date': 'Jan 05, 2024',
      'price': '₹1,500',
      'status': 'PROCESSING',
      'estimate': 'Items being prepared',
      'images': [
        'https://images.unsplash.com/photo-1593150501174-d9a042d15c39?q=80&w=150&auto=format&fit=crop',
      ],
    },
  ];

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
                const SizedBox(height: 72),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 20,
                    vertical: 40,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) ...[
                        _buildSidebar(),
                        const SizedBox(width: 60),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isDesktop) ...[
                              _buildMobileTabSelector(),
                              const SizedBox(height: 32),
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
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sidebarItem(0, "Profile", Icons.person_outline),
          _sidebarItem(1, "Saved Addresses", Icons.location_on_outlined),
          _sidebarItem(2, "Order History", Icons.shopping_bag_outlined),
          _sidebarItem(3, "Returns", Icons.replay_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
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
          // TODO: Implement logout
        } else if (index == 1) {
          Navigator.pushNamed(context, Routes.savedAddresses);
        } else {
          setState(() => _selectedTabIndex = index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isLogout
                  ? AppTheme.errorRed
                  : (isSelected ? AppTheme.terracotta : AppTheme.textLight),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.terracotta : Colors.transparent,
          border: Border.all(color: isSelected ? AppTheme.terracotta : AppTheme.divider),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    switch (_selectedTabIndex) {
      case 2:
        return _buildOrderHistory();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(Icons.construction, size: 60, color: AppTheme.divider),
              const SizedBox(height: 20),
              Text(
                "Section Under Development",
                style: GoogleFonts.jost(color: AppTheme.textLight),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildOrderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Order History", style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 32),
        ..._dummyOrders.map((order) => _buildOrderCard(order)).toList(),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
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
                    "Order #${order['id']}",
                    style: GoogleFonts.jost(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    "Placed on ${order['date']}",
                    style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
              _buildStatusBadge(order['status']),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (order['images'] as List<String>).map((img) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.divider),
                          image: DecorationImage(
                            image: NetworkImage(img),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total Amount", style: GoogleFonts.jost(fontSize: 11, color: AppTheme.textLight)),
                  Text(
                    order['price'],
                    style: GoogleFonts.jost(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['estimate'],
                style: GoogleFonts.jost(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: order['status'] == 'DELIVERED' ? AppTheme.successGreen : AppTheme.textDark,
                ),
              ),
              Row(
                children: _buildActionButtons(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'IN TRANSIT':
        color = Colors.orange[700]!;
        break;
      case 'DELIVERED':
        color = Colors.green[700]!;
        break;
      default:
        color = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: GoogleFonts.jost(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: color,
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> order) {
    if (order['status'] == 'IN TRANSIT') {
      return [
        _smallButton("Track Order", isPrimary: true),
        const SizedBox(width: 12),
        _smallButton("View Details", isPrimary: false),
      ];
    } else if (order['status'] == 'DELIVERED') {
      List<Widget> buttons = [
        _smallButton("Order Again", isPrimary: true),
        const SizedBox(width: 12),
        _smallButton("Invoice", isPrimary: false),
      ];
      if (order['returnable'] == true) {
        buttons.insert(0, Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _smallButton("Return", isPrimary: false),
        ));
      }
      return buttons;
    }
    return [
      _smallButton("View Details", isPrimary: false),
    ];
  }

  Widget _smallButton(String label, {required bool isPrimary}) {
    return InkWell(
      onTap: () {
        // TODO: Action
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.terracotta : Colors.transparent,
          border: Border.all(color: AppTheme.terracotta),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : AppTheme.terracotta,
          ),
        ),
      ),
    );
  }
}
