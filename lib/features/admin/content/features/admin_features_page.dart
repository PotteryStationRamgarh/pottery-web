import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/config_provider.dart';
import 'package:provider/provider.dart';

class AdminFeaturesPage extends StatefulWidget {
  const AdminFeaturesPage({super.key});

  @override
  State<AdminFeaturesPage> createState() => _AdminFeaturesPageState();
}

class _AdminFeaturesPageState extends State<AdminFeaturesPage> {
  // Uses Watch instead of purely isolated state because toggles auto-save 
  // and we want UI to reflect globally.
  
  Future<void> _toggleMaintenance(BuildContext context, bool value, ConfigProvider config) async {
    try {
      final updated = config.features.copyWith(maintenanceMode: value);
      await FirestoreService.updateConfig('features', updated.toMap());
      if (context.mounted) {
        // Also update local provider so UI updates instantly across app without waiting for refresh
        config.updateFeatures(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Maintenance mode Enabled' : 'Maintenance mode Disabled'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final isMaintenance = config.features.maintenanceMode;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Features', style: AppTheme.headingLarge),
                const SizedBox(height: 4),
                Text('Control app-wide feature flags', style: AppTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Maintenance Mode', style: AppTheme.headingMedium.copyWith(color: AppTheme.textDark)),
                      Switch(
                        value: isMaintenance,
                        activeColor: AppTheme.primaryBrown,
                        onChanged: (val) => _toggleMaintenance(context, val, config),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When enabled, users see a maintenance screen instead of the app.',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
