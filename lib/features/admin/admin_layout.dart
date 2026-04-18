import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/config_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/utils/responsive_utils.dart';
import '../../app/routes.dart';

import 'dashboard/pages/dashboard_page.dart';
import 'content/branding/admin_branding_page.dart';
import 'content/exhibition/admin_exhibition_page.dart';
import 'catalog/categories/admin_categories_list_page.dart';
import 'catalog/all_products/admin_products_list_page.dart';
import 'catalog/exclusive_products/admin_exclusive_list_page.dart';
import 'orders/admin_orders_page.dart';
import 'support/admin_support_page.dart';
import 'settings/admin_settings_page.dart';
import '../../core/repositories/exhibition_repository.dart';
import 'catalog/repositories/product_repository.dart';
import '../../core/services/storefront_cleanup_service.dart';
import '../../models/product.dart';
import 'customers/admin_customers_page.dart';
import 'notifications/admin_notifications_page.dart';
import 'content/about_us/admin_about_us_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _incompleteCount = 0;

  List<Widget> get _pages => [
    AdminDashboardPage(onNavigate: _navigate),   // 0
    const AdminBrandingPage(),                   // 1
    const AdminExhibitionPage(),                 // 2
    const AdminCategoriesListPage(),             // 3
    const AdminProductsListPage(),               // 4
    const AdminExclusiveListPage(),              // 5
    const AdminProductsListPage(showOnlyIncomplete: true), // 6
    const AdminSettingsPage(),                   // 7
    const AdminOrdersPage(),                     // 8
    const AdminSupportPage(),                    // 9
    const AdminCustomersPage(),                  // 10
    const AdminNotificationsPage(),              // 11
    const AdminAboutUsPage(),                    // 12
  ];

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: auto-clean exhibitions older than 30 days
    ExhibitionRepository.deleteOldExhibitions();
    StorefrontCleanupService.runMaintenanceIfDue();
    _loadNotificationCounts();
  }

  Future<void> _loadNotificationCounts() async {
    try {
      final results = await Future.wait<dynamic>([
        ProductRepository.getProducts(forceRefresh: true),
      ]);

      final products = results[0] as List<Product>;

      if (mounted) {
        setState(() {
          _incompleteCount = products.where(_isIncomplete).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification counts: $e');
    }
  }

  bool _isIncomplete(Product p) {
    return p.mrp <= 0 ||
        p.sellingPrice <= 0 ||
        p.imageUrls.isEmpty ||
        p.categoryId.isEmpty ||
        p.description.trim().isEmpty ||
        p.stockCount < 0;
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    _loadNotificationCounts();
  }

  Widget _buildPage() {
    if (_selectedIndex >= 0 && _selectedIndex < _pages.length) {
      return _pages[_selectedIndex];
    }
    return _pages[0];
  }

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Branding';
      case 2:
        return 'Exhibition';
      case 3:
        return 'Categories';
      case 4:
        return 'Products';
      case 5:
        return 'Exclusives';
      case 6:
        return 'Incomplete Products';
      case 7:
        return 'Settings';
      case 8:
        return 'Orders';
      case 9:
        return 'Support';
      case 10:
        return 'Customers';
      case 11:
        return 'Notifications';
      case 12:
        return 'About Us';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildSidebar(BuildContext context, ConfigProvider config) {
    return Container(
      width: 250,
      color: AppTheme.appBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: AppLogo(
              logoUrl: config.branding.logoUrl,
              appName: config.branding.appName,
              lightMode: true,
              size: 32,
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                const _SidebarGroupLabel('MAIN'),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  index: 0,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                const SizedBox(height: 20),

                const _SidebarGroupLabel('CONTENT'),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.brush_outlined,
                  label: 'Branding',
                  index: 1,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.event_outlined,
                  label: 'Exhibition',
                  index: 2,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.info_outline,
                  label: 'About Us',
                  index: 12,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                const SizedBox(height: 20),

                const _SidebarGroupLabel('CATALOG'),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  index: 3,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  index: 4,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.star_outline,
                  label: 'Exclusives',
                  index: 5,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.collections_bookmark_outlined,
                  label: 'Incomplete',
                  index: 6,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                  badgeCount: _incompleteCount,
                ),
                const SizedBox(height: 20),



                const _SidebarGroupLabel('OPERATIONS'),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Orders',
                  index: 8,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Customers',
                  index: 10,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  index: 11,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                _SidebarItem(
                  icon: Icons.support_agent_outlined,
                  label: 'Support',
                  index: 9,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),
                const SizedBox(height: 20),

                const _SidebarGroupLabel('SYSTEM'),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  index: 7,
                  selectedIndex: _selectedIndex,
                  onTap: _navigate,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pottery Station Ramgarh',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white24,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return PopScope(
      // Allow popping only if on dashboard (index 0)
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex > 0) {
          // Browser back pressed on a sub-page → go to dashboard
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.background,
        // Sidebar slides in as drawer on mobile
        drawer: isDesktop
            ? null
            : Drawer(child: _buildSidebar(context, config)),
        body: Row(
          children: [
            if (isDesktop) _buildSidebar(context, config),

            Expanded(
              child: Column(
                children: [
                  // ── Top bar ──
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Hamburger on mobile — LEFT side
                        if (!isDesktop)
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: AppTheme.textDark,
                            ),
                            tooltip: 'Menu',
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),

                        if (!isDesktop) const SizedBox(width: 4),

                        // Back arrow — show on sub-pages (not dashboard)
                        if (_selectedIndex > 0)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.textDark,
                              size: 20,
                            ),
                            tooltip: 'Back to Dashboard',
                            onPressed: () => setState(() => _selectedIndex = 0),
                          ),

                        Expanded(
                          child: Text(
                            _currentTitle,
                            style: AppTheme.headingLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const Spacer(),

                        // Profile avatar — RIGHT side (always visible)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, Routes.profile),
                            child: const CircleAvatar(
                              backgroundColor: AppTheme.primaryBrown,
                              radius: 18,
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Page content ──
                  Expanded(child: _buildPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  final String text;
  const _SidebarGroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryBrown.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(index),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? AppTheme.primaryBrown : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTheme.bodyMedium.copyWith(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
