import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  /// If provided, renders as a filled coloured card; otherwise white card.
  final Color? accentColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  bool get _isDark => accentColor != null;

  @override
  Widget build(BuildContext context) {
    final bg = accentColor ?? AppTheme.white;
    final fg = _isDark ? AppTheme.white : AppTheme.textDark;
    final fgSub = _isDark
        ? AppTheme.white.withOpacity(0.75)
        : AppTheme.textLight;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDark ? Colors.transparent : AppTheme.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: fgSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                icon,
                color: _isDark ? AppTheme.white : AppTheme.primaryBrown,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.displayLarge.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
