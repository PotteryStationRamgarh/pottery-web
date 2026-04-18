import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/exhibition_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/customer/widgets/image_placeholder.dart';
import 'exhibition_badge.dart';

/// Card widget for displaying a single exhibition
/// Shows priority badge, image, title, location, time, and status message
class ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final VoidCallback? onTap;

  const ExhibitionCard({required this.exhibition, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final isMuted = exhibition.isPast;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isMuted ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isMuted ? Colors.grey[100] : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      color: AppTheme.divider.withValues(alpha: 0.3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: exhibition.imageUrl.isNotEmpty
                        ? Image.network(
                            exhibition.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ImagePlaceholder(aspectRatio: 16 / 9),
                          )
                        : const ImagePlaceholder(aspectRatio: 16 / 9),
                  ),
                  // Opacity overlay for past exhibitions
                  if (isMuted)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  // Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ExhibitionBadge(status: exhibition.status),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      exhibition.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isMuted
                            ? AppTheme.textDark.withValues(alpha: 0.6)
                            : AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isMuted
                              ? Colors.grey[600]
                              : AppTheme.primaryBrown,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            exhibition.location,
                            style: GoogleFonts.jost(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isMuted
                                  ? Colors.grey[600]
                                  : AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: isMuted
                              ? Colors.grey[600]
                              : AppTheme.primaryBrown,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exhibition.displayTime,
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isMuted
                                ? Colors.grey[600]
                                : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Address (if space)
                    if (exhibition.address.isNotEmpty)
                      Text(
                        exhibition.address,
                        style: GoogleFonts.jost(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: isMuted
                              ? Colors.grey[600]
                              : AppTheme.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    // Contextual message
                    if (exhibition.contextualMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _getMessageBgColor(exhibition.status, isMuted),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exhibition.contextualMessage,
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _getMessageTextColor(
                              exhibition.status,
                              isMuted,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMessageBgColor(ExhibitionStatus status, bool isMuted) {
    if (isMuted) return Colors.grey[300]!;
    switch (status) {
      case ExhibitionStatus.current:
        if (exhibition.isLastDay) {
          return const Color(0xFFFFEAEA);
        }
        return const Color(0xFFEBF7FF);
      case ExhibitionStatus.future:
        return const Color(0xFFEBF7FF);
      case ExhibitionStatus.past:
        return Colors.grey[200]!;
    }
  }

  Color _getMessageTextColor(ExhibitionStatus status, bool isMuted) {
    if (isMuted) return Colors.grey[700]!;
    switch (status) {
      case ExhibitionStatus.current:
        if (exhibition.isLastDay) {
          return const Color(0xFFDC2626);
        }
        return const Color(0xFF1E40AF);
      case ExhibitionStatus.future:
        return const Color(0xFF1E40AF);
      case ExhibitionStatus.past:
        return Colors.grey[600]!;
    }
  }
}
