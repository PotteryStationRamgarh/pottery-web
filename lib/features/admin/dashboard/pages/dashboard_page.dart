import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/remote_config_service.dart';
import '../dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/system_status_card.dart';
import '../widgets/maintenance_toggle_card.dart';

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

class _DashboardView extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const _DashboardView({this.onNavigate});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  // Cache futures so FutureBuilder doesn't re-fire on every rebuild
  late final Future<bool> _firestoreFuture;
  late final bool _storageOk;

  @override
  void initState() {
    super.initState();
    _firestoreFuture = _checkFirestore();
    _storageOk = _checkStorage();
  }

  /// Real Firestore ping — checks that the db is reachable
  Future<bool> _checkFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));
      return true;
    } catch (e) {
      debugPrint('Firestore ping error: $e');
      return false;
    }
  }

  /// Storage is configured when Remote Config has delivered the R2 secrets
  bool _checkStorage() {
    return RemoteConfigService.r2AccessKeyId.isNotEmpty &&
        RemoteConfigService.r2SecretAccessKey.isNotEmpty &&
        RemoteConfigService.r2AccountId.isNotEmpty;
  }

  void _nav(int i) => widget.onNavigate?.call(i);

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
              firestoreFuture: _firestoreFuture,
              storageOk: _storageOk,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ROW
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
      value: d.isLoading
          ? '—'
          : title == 'Total Inventory'
              ? '${d.productCount}'
              : '${d.exclusiveCount}',
      icon: icon,
      accentColor: color,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  final ConfigProvider config;
  final DashboardProvider dashboard;
  final void Function(int) onNavigate;
  final Future<bool> firestoreFuture;
  final bool storageOk;

  const _BottomSection({
    required this.config,
    required this.dashboard,
    required this.onNavigate,
    required this.firestoreFuture,
    required this.storageOk,
  });

  static const _actions = [
    _ActionItem('Add Product',    Icons.inventory_2_outlined,      4),
    _ActionItem('Add Category',   Icons.category_outlined,         3),
    _ActionItem('Add Exclusive',  Icons.star_border_outlined,      5),
    _ActionItem('Add Exhibition', Icons.event_available_outlined,  2),
    _ActionItem('Edit Branding',  Icons.brush_outlined,            1),
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
          children: _actions
              .map((a) => QuickActionCard(
                    label: a.label,
                    icon: a.icon,
                    onTap: () => onNavigate(a.navIndex),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Overview', style: AppTheme.headingLarge),
        const SizedBox(height: 16),

        // ── System Status — future is cached, won't re-fire ──
        FutureBuilder<bool>(
          future: firestoreFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Checking system status…'),
                  ],
                ),
              );
            }

            return SystemStatusCard(
              isFirestoreConnected: snapshot.data!,
              isStorageConfigured: storageOk,
              isMaintenanceMode: config.features.maintenanceMode,
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Exhibition status card ──
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
              if (dashboard.isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBrown),
                )
              else if (dashboard.exhibitionStatus == 'None' ||
                  dashboard.exhibition.title.isEmpty)
                Text('No active or upcoming exhibitions.', style: AppTheme.bodyMedium)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(dashboard.exhibitionStatus).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dashboard.exhibitionStatus,
                        style: AppTheme.bodySmall.copyWith(
                          color: _statusColor(dashboard.exhibitionStatus),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dashboard.exhibition.title,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.primaryBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.terracotta),
                        const SizedBox(width: 4),
                        Text(dashboard.exhibition.location, style: AppTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          dashboard.exhibition.startDate != null &&
                                  dashboard.exhibition.endDate != null
                              ? '${dashboard.exhibition.startDate!.day}/${dashboard.exhibition.startDate!.month} — ${dashboard.exhibition.endDate!.day}/${dashboard.exhibition.endDate!.month}'
                              : 'Dates not set',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (dashboard.exhibition.displayTime.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined, size: 14, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text(dashboard.exhibition.displayTime, style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':   return AppTheme.successGreen;
      case 'Upcoming': return AppTheme.primaryBrown;
      case 'Past':     return AppTheme.textLight;
      default:         return AppTheme.greyPlaceholder;
    }
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final int navIndex;
  const _ActionItem(this.label, this.icon, this.navIndex);
}