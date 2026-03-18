import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// HoverButton — primary action button used across all auth screens.
/// Has smooth hover effect with shadow and letter spacing animation.
/// Shows loading spinner when isLoading is true.
class HoverButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;

  const HoverButton({
    super.key,
    required this.onTap,
    required this.label,
    this.isLoading = false,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.primaryBrown.withOpacity(0.85)
              : AppTheme.primaryBrown,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBrown.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.primaryBrown.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.white,
                      ),
                    )
                  : AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTheme.labelLarge.copyWith(
                        letterSpacing: _isHovered ? 1.8 : 1.2,
                      ),
                      child: Text(widget.label.toUpperCase()),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}