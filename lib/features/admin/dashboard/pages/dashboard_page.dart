import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/featured_card.dart';
import '../widgets/system_status_card.dart';

// Nav index mapping:
// 0 Dashboard | 1 Branding | 2 Hero Section | 3 Contact | 4 Content | 5 Social | 6 Features | 7 Exhibition | 8 Categories | 9 Products | 10 Exclusive | 11 Settings

class AdminDashboardPage extends StatelessWidget {
  final void Function(int index)? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: _DashboardView(onNavigate: onNavigate),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final void Function(int index)? onNavigate;
  const _DashboardView({this.onNavigate});

  void _nav(int i) => onNavigate?.call(i);

  @override
  Widget build(BuildContext context) {
    final config    = context.watch<ConfigProvider>();
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ───────────────────────────────────────────────────────
            const DashboardHeader(),
            const SizedBox(height: 24),

            // ── STATS (Total Inventory + Exclusive ONLY) ─────────────────────
            _StatsRow(dashboard: dashboard),
            const SizedBox(height: 24),

            // ── HERO PREVIEW ─────────────────────────────────────────────────
            SizedBox(
              height: 140,
              width: double.infinity,
              child: FeaturedCard(onCtaTap: () => _nav(2)), // 2 = Hero Section
            ),
            const SizedBox(height: 24),

            // ── LOWER SECTION: Quick Actions (Left) | Status & Exhibition (Right) 
            _BottomSection(
              config: config,
              dashboard: dashboard,
              onNavigate: _nav,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row — 2 cards
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final DashboardProvider dashboard;
  const _StatsRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isMobile = c.maxWidth < 600;
      if (isMobile) {
        return Column(
          children: [
            _statCard('Total Inventory', dashboard, Icons.inventory_2_outlined, AppTheme.primaryBrown),
            const SizedBox(height: 16),
            _statCard('Exclusive Products', dashboard, Icons.star_outline, AppTheme.warmClay),
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _statCard('Total Inventory', dashboard, Icons.inventory_2_outlined, AppTheme.primaryBrown)),
            const SizedBox(width: 20),
            Expanded(child: _statCard('Exclusive Products', dashboard, Icons.star_outline, AppTheme.warmClay)),
          ],
        ),
      );
    });
  }

  Widget _statCard(String title, DashboardProvider d, IconData icon, Color? color) {
    return StatCard(
      title: title,
      value: d.isLoading ? '—' :
        title == 'Total Inventory' ? '${d.productCount}' :
        '${d.exclusiveCount}',
      icon: icon,
      accentColor: color,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Section
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  final ConfigProvider config;
  final DashboardProvider dashboard;
  final void Function(int) onNavigate;

  const _BottomSection({
    required this.config,
    required this.dashboard,
    required this.onNavigate,
  });

  static const _actions = [
    _ActionItem('Add New Product',     Icons.add_box_outlined,     9), // Products
    _ActionItem('Add Exclusive',       Icons.star_border_outlined, 10), // Exclusive
    _ActionItem('Add Exhibition',      Icons.event_available_outlined, 7), // Exhibition
    _ActionItem('Edit Contact',        Icons.contact_mail_outlined, 3), // Contact
    _ActionItem('Edit Content',        Icons.article_outlined,      4), // Content
    _ActionItem('Edit Social',         Icons.share_outlined,        5), // Social
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 800) {
        return Column(
          children: [
            _buildLeftColumn(),
            const SizedBox(height: 24),
            _buildRightColumn(),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildLeftColumn()),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildRightColumn()),
        ],
      );
    });
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTheme.headingLarge),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.25,
          children: _actions.map((a) => QuickActionCard(
            label: a.label,
            icon: a.icon,
            onTap: () => onNavigate(a.navIndex),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    final exhibitionStatusText = dashboard.isLoading ? '—' : dashboard.exhibitionStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Overview', style: AppTheme.headingLarge),
        const SizedBox(height: 16),
        SystemStatusCard(
          isFirestoreConnected: true,
          isStorageConfigured: false,
          isMaintenanceMode: config.features.maintenanceMode,
        ),
        const SizedBox(height: 16),
        // Exhibition Status Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrown.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Exhibition', style: AppTheme.headingMedium),
                  Icon(Icons.event_outlined, color: AppTheme.primaryBrown, size: 24),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Status', style: AppTheme.bodyMedium),
                  Text(
                    exhibitionStatusText,
                    style: AppTheme.bodyMedium.copyWith(
                      color: exhibitionStatusText == 'Active'
                          ? AppTheme.terracotta
                          : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final int navIndex;
  const _ActionItem(this.label, this.icon, this.navIndex);
}
