import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// HoverButton — action button used across all auth screens.
/// Has smooth hover effect with shadow animation.
/// Shows loading spinner when isLoading is true.
///
/// [isSecondary] — if true renders as outlined button instead of filled
/// Used for lower-priority actions like "Resend Email"
class HoverButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final bool isSecondary;

  const HoverButton({
    super.key,
    required this.onTap,
    required this.label,
    this.isLoading    = false,
    this.isSecondary  = false,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Disabled state — button grayed out when onTap is null
    final isDisabled = widget.onTap == null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: widget.isSecondary
            ? BoxDecoration(
                // Outlined style for secondary action
                color: _isHovered
                    ? AppTheme.primaryBrown.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDisabled
                      ? AppTheme.divider
                      : AppTheme.primaryBrown.withOpacity(0.5),
                  width: 1.5,
                ),
              )
            : BoxDecoration(
                // Filled style for primary action
                color: isDisabled
                    ? AppTheme.divider
                    : _isHovered
                        ? AppTheme.primaryBrown.withOpacity(0.85)
                        : AppTheme.primaryBrown,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDisabled
                    ? []
                    : _isHovered
                        ? [
                            BoxShadow(
                              color:      AppTheme.primaryBrown.withOpacity(0.3),
                              blurRadius: 16,
                              offset:     const Offset(0, 6),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color:      AppTheme.primaryBrown.withOpacity(0.15),
                              blurRadius: 8,
                              offset:     const Offset(0, 3),
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
                  ? SizedBox(
                      height: 22,
                      width:  22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isSecondary
                            ? AppTheme.primaryBrown
                            : AppTheme.white,
                      ),
                    )
                  : AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTheme.labelLarge.copyWith(
                        letterSpacing: _isHovered ? 1.8 : 1.2,
                        color: widget.isSecondary
                            ? isDisabled
                                ? AppTheme.greyPlaceholder
                                : AppTheme.primaryBrown
                            : isDisabled
                                ? AppTheme.greyPlaceholder
                                : AppTheme.white,
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