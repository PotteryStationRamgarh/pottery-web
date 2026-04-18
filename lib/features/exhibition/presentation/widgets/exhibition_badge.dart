import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/exhibition_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Badge widget to display exhibition status
class ExhibitionBadge extends StatelessWidget {
  final ExhibitionStatus status;

  const ExhibitionBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color backgroundColor;
    late Color textColor;

    switch (status) {
      case ExhibitionStatus.current:
        label = 'Live Now';
        backgroundColor = const Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case ExhibitionStatus.future:
        label = 'Upcoming';
        backgroundColor = const Color(0xFF3B82F6);
        textColor = Colors.white;
        break;
      case ExhibitionStatus.past:
        label = 'Ended';
        backgroundColor = Colors.grey[400]!;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.jost(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
