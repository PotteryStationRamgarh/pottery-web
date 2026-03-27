import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/remote_config_service.dart';
import '../dashboard_provider.dart';
import '../../../../models/app_config.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/system_status_card.dart';
import '../widgets/maintenance_toggle_card.dart';

class AdminDashboardPage extends StatelessWidget {
  final void Function(int index)? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  // ✅ FIX 2: Storage Check (Matches MediaService hardcoded values)
  bool _checkStorage() {
    const String publicUrlBase = 'https://pub-32b0eccfedfb4b29980313569dfccc15.r2.dev';
    return publicUrlBase.isNotEmpty &&
           RemoteConfigService.r2AccessKeyId.isNotEmpty &&
           RemoteConfigService.r2SecretAccessKey.isNotEmpty;
  }

  // ✅ FIX 2: Firestore Check
  Future<bool> _checkFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .limit(1)
          .get();
      return true;
    } catch (e) {
      debugPrint("Firestore error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: _DashboardView(
        onNavigate: onNavigate,
        checkFirestore: _checkFirestore,
        checkStorage: _checkStorage,
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final void Function(int index)? onNavigate;
  final Future<bool> Function() checkFirestore;
  final bool Function() checkStorage;

  const _DashboardView({
    this.onNavigate,
    required this.checkFirestore,
    required this.checkStorage,
  });

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
            const SizedBox(height: 16),

            // ── MAINTENANCE MODE ─────────────────────────────────────────────
            MaintenanceToggleCard(
              isEnabled: config.features.maintenanceMode,
              onChanged: (val) {
                context.read<ConfigProvider>().updateFeatures(
                      config.features.copyWith(maintenanceMode: val),
                    );
              },
            ),
            const SizedBox(height: 24),

            // ── STATS ────────────────────────────────────────────────────────
            _StatsRow(dashboard: dashboard),
            const SizedBox(height: 24),

            // ── LOWER SECTION ────────────────────────────────────────────────
            _BottomSection(
              config: config,
              dashboard: dashboard,
              onNavigate: _nav,
              checkFirestore: checkFirestore,
              checkStorage: checkStorage,
            ),
          ],
        ),
      ),
    );
  }
}

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

class _BottomSection extends StatelessWidget {
  final ConfigProvider config;
  final DashboardProvider dashboard;
  final void Function(int) onNavigate;
  final Future<bool> Function() checkFirestore;
  final bool Function() checkStorage;

  const _BottomSection({
    required this.config,
    required this.dashboard,
    required this.onNavigate,
    required this.checkFirestore,
    required this.checkStorage,
  });

  static const _actions = [
    _ActionItem('Add Product',    Icons.inventory_2_outlined,   3), 
    _ActionItem('Add Category',   Icons.category_outlined,      2), 
    _ActionItem('Add Exclusive',  Icons.star_border_outlined,   4), 
    _ActionItem('Add Exhibition', Icons.event_available_outlined, 20), // Exhibition Logic will be integrated
    _ActionItem('Edit Branding',  Icons.brush_outlined,         1), 
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 900) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeftColumn(isMobile: true),
            const SizedBox(height: 24),
            _buildRightColumn(),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildLeftColumn(isMobile: false)),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildRightColumn()),
        ],
      );
    });
  }

  Widget _buildLeftColumn({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTheme.headingLarge),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 3,
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
        
        // ✅ FIX 2: REAL STATUS CHECKS
        FutureBuilder<bool>(
          future: checkFirestore(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final storageOk = checkStorage();

            return SystemStatusCard(
              isFirestoreConnected: snapshot.data!,
              isStorageConfigured: storageOk,
              isMaintenanceMode: config.features.maintenanceMode,
            );
          },
        ),
        
        const SizedBox(height: 16),
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
                  const Icon(Icons.event_outlined, color: AppTheme.primaryBrown, size: 24),
                ],
              ),
              const SizedBox(height: 24),
              // ✅ FIX 5: Real Exhibition Data Display
              if (dashboard.exhibitionStatus == 'None' || dashboard.exhibition.title.isEmpty)
                Text('No active or upcoming exhibitions.', style: AppTheme.bodyMedium)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dashboard.exhibition.title, 
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.primaryBrown,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.terracotta),
                        const SizedBox(width: 4),
                        Text(dashboard.exhibition.location, style: AppTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          dashboard.exhibition.startDate != null && dashboard.exhibition.endDate != null
                            ? "${dashboard.exhibition.startDate!.day}/${dashboard.exhibition.startDate!.month} - ${dashboard.exhibition.endDate!.day}/${dashboard.exhibition.endDate!.month}"
                            : "Dates not set",
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dashboard.exhibitionStatus == 'Upcoming' 
                          ? dashboard.exhibition.upcomingMessage 
                          : dashboard.exhibition.displayTime,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.terracotta,
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
