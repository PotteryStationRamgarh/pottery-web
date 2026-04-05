import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class MaintenanceToggleCard extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const MaintenanceToggleCard({
    super.key,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppTheme.terracotta.withOpacity(0.08)
            : AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled
              ? AppTheme.terracotta.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.terracotta.withOpacity(0.12)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.construction_outlined,
              color: isEnabled ? AppTheme.terracotta : AppTheme.textLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance Mode',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled
                      ? 'Site is in maintenance — only admins can access'
                      : 'Site is live and accessible to all users',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: AppTheme.terracotta,
          ),
        ],
      ),
    );
  }
}
