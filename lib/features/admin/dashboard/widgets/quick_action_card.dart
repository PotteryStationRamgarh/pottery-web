import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class QuickActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBrown : AppTheme.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? Colors.transparent : AppTheme.divider,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBrown.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppTheme.white.withOpacity(0.15)
                      : AppTheme.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: _hovered ? AppTheme.white : AppTheme.primaryBrown,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMedium.copyWith(
                  color: _hovered ? AppTheme.white : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
