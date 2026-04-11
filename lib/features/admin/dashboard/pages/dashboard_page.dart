import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/repositories/custom_order_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../models/custom_order_model.dart';
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
  late final Future<bool> _firestoreFuture;
  late final bool _storageOk;

  @override
  void initState() {
    super.initState();
    _firestoreFuture = _checkFirestore();
    _storageOk = _checkStorage();
  }

  Future<bool> _checkFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _checkStorage() {
    return RemoteConfigService.r2AccessKeyId.isNotEmpty &&
        RemoteConfigService.r2SecretAccessKey.isNotEmpty &&
        RemoteConfigService.r2AccountId.isNotEmpty;
  }

  void _nav(int i) => widget.onNavigate?.call(i);

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final isPageNarrow = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isPageNarrow ? 24 : 60,
          vertical: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: 24),

            // 1. Full-width top cards
            MaintenanceToggleCard(
              isEnabled: config.features.maintenanceMode,
              onChanged: (val) {
                context.read<ConfigProvider>().updateFeatures(
                  config.features.copyWith(maintenanceMode: val),
                );
              },
            ),
            const SizedBox(height: 24),
            _StatsRow(dashboard: dashboard),
            const SizedBox(height: 32),
            // Custom Order Notifications
            FutureBuilder<List<CustomOrderModel>>(
              future: CustomOrderRepository.getCustomOrders(),
              builder: (context, snapshot) {
                final pendingCount = snapshot.data
                        ?.where((order) => order.status == 'pending')
                        .length ??
                    0;
                if (pendingCount == 0) return const SizedBox.shrink();
                return _DashboardNotification(
                  icon: Icons.notifications_active_outlined,
                  message: '$pendingCount custom product request(s) need review.',
                  buttonLabel: 'Open Requests',
                  onPressed: () => _nav(6),
                );
              },
            ),

            // Incomplete Product Notifications
            if (dashboard.incompleteProductCount > 0)
              _DashboardNotification(
                icon: Icons.warning_amber_rounded,
                message: '${dashboard.incompleteProductCount} product(s) in your collection are missing critical details (MRP, Images, etc.).',
                buttonLabel: 'Fix Issues',
                onPressed: () => _nav(8),
              ),

            // 2. Main content row (Quick Actions + System Overview)
            if (isPageNarrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickActionSection(onNavigate: _nav, isNarrow: isPageNarrow),
                  const SizedBox(height: 48),
                  _SystemOverviewSection(
                    config: config,
                    dashboard: dashboard,
                    firestoreFuture: _firestoreFuture,
                    storageOk: _storageOk,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Quick Actions (Larger)
                  Expanded(
                    flex: 3,
                    child: _QuickActionSection(
                      onNavigate: _nav,
                      isNarrow: isPageNarrow,
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Right: System Overview
                  Expanded(
                    flex: 2,
                    child: _SystemOverviewSection(
                      config: config,
                      dashboard: dashboard,
                      firestoreFuture: _firestoreFuture,
                      storageOk: _storageOk,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionSection extends StatelessWidget {
  final void Function(int) onNavigate;
  final bool isNarrow;
  const _QuickActionSection({required this.onNavigate, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTheme.headingLarge),
        const SizedBox(height: 16),
        _QuickActionsGrid(onNavigate: onNavigate, isNarrow: isNarrow),
      ],
    );
  }
}

class _SystemOverviewSection extends StatelessWidget {
  final ConfigProvider config;
  final DashboardProvider dashboard;
  final Future<bool> firestoreFuture;
  final bool storageOk;

  const _SystemOverviewSection({
    required this.config,
    required this.dashboard,
    required this.firestoreFuture,
    required this.storageOk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Overview', style: AppTheme.headingLarge),
        const SizedBox(height: 16),
        _SystemStatusWidget(
          firestoreFuture: firestoreFuture,
          storageOk: storageOk,
          isMaintenanceMode: config.features.maintenanceMode,
        ),
        const SizedBox(height: 24),
        _ExhibitionWidget(dashboard: dashboard),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardProvider dashboard;
  const _StatsRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: [
              _statCard(
                'Total Inventory',
                dashboard,
                Icons.inventory_2_outlined,
                AppTheme.primaryBrown,
              ),
              const SizedBox(height: 16),
              _statCard(
                'Exclusive Products',
                dashboard,
                Icons.star_outline,
                AppTheme.warmClay,
              ),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Inventory',
                  dashboard,
                  Icons.inventory_2_outlined,
                  AppTheme.primaryBrown,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _statCard(
                  'Exclusive Products',
                  dashboard,
                  Icons.star_outline,
                  AppTheme.warmClay,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
    String title,
    DashboardProvider d,
    IconData icon,
    Color? color,
  ) {
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

class _SystemStatusWidget extends StatelessWidget {
  final Future<bool> firestoreFuture;
  final bool storageOk;
  final bool isMaintenanceMode;

  const _SystemStatusWidget({
    required this.firestoreFuture,
    required this.storageOk,
    required this.isMaintenanceMode,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: firestoreFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryBrown,
            ),
          );
        }
        return SystemStatusCard(
          isFirestoreConnected: snapshot.data!,
          isStorageConfigured: storageOk,
          isMaintenanceMode: isMaintenanceMode,
        );
      },
    );
  }
}

class _ExhibitionWidget extends StatelessWidget {
  final DashboardProvider dashboard;
  const _ExhibitionWidget({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final status = dashboard.exhibitionStatus;
    final heading = status == 'Upcoming'
        ? 'Next Exhibition'
        : status == 'Active'
        ? 'Current Exhibition'
        : 'Past Exhibition';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: AppTheme.headingLarge),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.divider),
          ),
          child: dashboard.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBrown,
                  ),
                )
              : dashboard.exhibition.title.isEmpty
              ? Text(
                  'No active, upcoming or past exhibitions found.',
                  style: AppTheme.bodyMedium,
                )
              : _buildExhibitionDetails(dashboard),
        ),
      ],
    );
  }

  Widget _buildExhibitionDetails(DashboardProvider d) {
    String _fmt(DateTime dt) {
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yy = dt.year.toString().substring(2);
      return '$dd/$mm/$yy';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                d.exhibition.title,
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 22,
                  color: AppTheme.primaryBrown,
                ),
              ),
            ),
            _StatusBadgeSmall(status: d.exhibitionStatus),
          ],
        ),
        const SizedBox(height: 16),
        _ExhibitionInfoLine(
          icon: Icons.location_on_outlined,
          text: d.exhibition.location,
        ),
        const SizedBox(height: 8),
        _ExhibitionInfoLine(
          icon: Icons.calendar_today_outlined,
          text: d.exhibition.startDate != null
              ? '${_fmt(d.exhibition.startDate!)} – ${_fmt(d.exhibition.endDate!)}'
              : 'Dates not set',
        ),
      ],
    );
  }
}

class _ExhibitionInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ExhibitionInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textLight),
        const SizedBox(width: 12),
        Text(text, style: AppTheme.bodyMedium),
      ],
    );
  }
}

class _StatusBadgeSmall extends StatelessWidget {
  final String status;
  const _StatusBadgeSmall({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Active'
        ? AppTheme.successGreen
        : status == 'Upcoming'
        ? AppTheme.primaryBrown
        : AppTheme.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final void Function(int) onNavigate;
  final bool isNarrow;
  const _QuickActionsGrid({required this.onNavigate, required this.isNarrow});

  static const _actions = [
    _ActionItem('Add Product', Icons.inventory_2_outlined, 4),
    _ActionItem('Add Category', Icons.category_outlined, 3),
    _ActionItem('Add Exclusive', Icons.star_border_outlined, 5),
    _ActionItem('Custom Requests', Icons.design_services_outlined, 6),
    _ActionItem('Custom Collection', Icons.collections_bookmark_outlined, 8),
    _ActionItem('Add Exhibition', Icons.event_outlined, 2),
    _ActionItem('Edit Branding', Icons.brush_outlined, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isNarrow ? 2 : 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: _actions
          .map(
            (a) => QuickActionCard(
              label: a.label,
              icon: a.icon,
              onTap: () => onNavigate(a.navIndex),
            ),
          )
          .toList(),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final int navIndex;
  const _ActionItem(this.label, this.icon, this.navIndex);
}

class _DashboardNotification extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _DashboardNotification({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.terracotta),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.terracotta),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

