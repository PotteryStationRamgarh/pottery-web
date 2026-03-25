import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/config_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';

import 'dashboard/pages/dashboard_page.dart';
import 'content/branding/admin_branding_page.dart';
import 'hero_section/admin_hero_section_page.dart';
import 'content/contact/admin_contact_page.dart';
import 'content/content_page/admin_content_page.dart';
import 'content/social/admin_social_page.dart';
import 'content/features/admin_features_page.dart';
import 'exhibition/admin_exhibition_page.dart';

import 'catalog/categories/admin_categories_page.dart';
import 'all_products/admin_all_products_page.dart';
import 'exclusive_products/admin_exclusive_products_page.dart';

import 'settings/admin_settings_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:  return AdminDashboardPage(onNavigate: _navigate);
      case 1:  return const AdminBrandingPage();
      case 2:  return const AdminHeroSectionPage();
      case 3:  return const AdminContactPage();
      case 4:  return const AdminContentPage();
      case 5:  return const AdminSocialPage();
      case 6:  return const AdminFeaturesPage();
      case 7:  return const AdminExhibitionPage();
      case 8:  return const AdminCategoriesPage();
      case 9:  return const AdminAllProductsPage();
      case 10: return const AdminExclusiveProductsPage();
      case 11: return const AdminSettingsPage();
      default: return AdminDashboardPage(onNavigate: _navigate);
    }
  }

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:  return 'Dashboard';
      case 1:  return 'Branding';
      case 2:  return 'Hero Section';
      case 3:  return 'Contact Information';
      case 4:  return 'Content';
      case 5:  return 'Social Links';
      case 6:  return 'Features';
      case 7:  return 'Exhibition';
      case 8:  return 'Categories';
      case 9:  return 'Products';
      case 10: return 'Exclusive Products';
      case 11: return 'Settings';
      default: return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      body: Row(
        children: [
          // ── SIDEBAR ──────────────────────────────────────────────────────
          Container(
            width: 240,
            color: AppTheme.appBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
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
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    children: [
                      _SidebarGroupLabel('MAIN'),
                      _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0, selectedIndex: _selectedIndex, onTap: _navigate),
                      
                      const SizedBox(height: 16),
                      _SidebarGroupLabel('CONTENT'),
                      _SidebarItem(icon: Icons.brush_outlined, label: 'Branding', index: 1, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.text_fields_outlined, label: 'Hero Section', index: 2, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.contact_mail_outlined, label: 'Contact', index: 3, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.article_outlined, label: 'Content', index: 4, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.share_outlined, label: 'Social', index: 5, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.toggle_on_outlined, label: 'Features', index: 6, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.event_outlined, label: 'Exhibition', index: 7, selectedIndex: _selectedIndex, onTap: _navigate),

                      const SizedBox(height: 16),
                      _SidebarGroupLabel('CATALOG'),
                      _SidebarItem(icon: Icons.category_outlined, label: 'Categories', index: 8, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.inventory_2_outlined, label: 'Products', index: 9, selectedIndex: _selectedIndex, onTap: _navigate),
                      _SidebarItem(icon: Icons.star_outline, label: 'Exclusive Products', index: 10, selectedIndex: _selectedIndex, onTap: _navigate),

                      const SizedBox(height: 16),
                      _SidebarGroupLabel('SYSTEM'),
                      _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', index: 11, selectedIndex: _selectedIndex, onTap: _navigate),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pottery Station Ramgarh',
                    style: AppTheme.bodySmall
                        .copyWith(color: Colors.white24, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // ── MAIN CONTENT ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    border: Border(
                        bottom: BorderSide(color: AppTheme.divider)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentTitle,
                        style: AppTheme.headingLarge,
                      ),
                      const Spacer(),
                      const CircleAvatar(
                        backgroundColor: AppTheme.primaryBrown,
                        radius: 16,
                        child: Icon(Icons.person_outline,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Admin',
                        style: AppTheme.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
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
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textLight,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
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

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryBrown.withOpacity(0.15)
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: AppTheme.bodyMedium.copyWith(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
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
