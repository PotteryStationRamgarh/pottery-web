import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class SystemStatusCard extends StatelessWidget {
  final bool isFirestoreConnected;
  final bool isStorageConfigured;
  final bool isMaintenanceMode;

  const SystemStatusCard({
    super.key,
    required this.isFirestoreConnected,
    required this.isStorageConfigured,
    required this.isMaintenanceMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('System Status', style: AppTheme.headingMedium),
          const SizedBox(height: 20),
          _StatusRow(
            label: 'Firestore',
            status: isFirestoreConnected ? 'Connected' : 'Error',
            isGood: isFirestoreConnected,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Storage',
            status: isStorageConfigured ? 'Connected' : 'Not Configured',
            isGood: isStorageConfigured,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Mode',
            status: isMaintenanceMode ? 'Maintenance' : 'Live',
            isGood: !isMaintenanceMode,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final bool isGood;

  const _StatusRow({
    required this.label,
    required this.status,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AppTheme.successGreen : AppTheme.errorRed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
