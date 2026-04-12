import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// AdminToggleSwitch — consistent toggle switch for isActive, hasCertificate, etc.
/// Handles label and value in one reusable widget.
class AdminToggleSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminToggleSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppTheme.primaryBrown,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
