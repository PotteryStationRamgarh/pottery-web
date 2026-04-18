import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/exhibition_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/customer/widgets/image_placeholder.dart';
import '../widgets/exhibition_badge.dart';

/// Detailed exhibition screen
/// Shows full information about an exhibition
class ExhibitionDetailScreen extends StatelessWidget {
  final ExhibitionModel exhibition;

  const ExhibitionDetailScreen({required this.exhibition, super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              width: double.infinity,
              height: isMobile ? 250 : 400,
              color: AppTheme.divider.withValues(alpha: 0.3),
              child: exhibition.imageUrl.isNotEmpty
                  ? Image.network(
                      exhibition.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ImagePlaceholder(aspectRatio: 16 / 9),
                    )
                  : const ImagePlaceholder(aspectRatio: 16 / 9),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exhibition.title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: isMobile ? 24 : 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ExhibitionBadge(status: exhibition.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Date Range
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Dates',
                    value: _formatDateRange(
                      exhibition.startDate,
                      exhibition.endDate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Hours',
                    value: '${exhibition.openTime} – ${exhibition.closeTime}',
                  ),
                  const SizedBox(height: 16),
                  // Display Time
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Display Time',
                    value: exhibition.displayTime,
                  ),
                  const SizedBox(height: 24),
                  // Location
                  _SectionTitle(title: 'Location'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrown.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppTheme.primaryBrown,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                exhibition.location,
                                style: GoogleFonts.jost(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exhibition.address,
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Contextual Message
                  if (exhibition.contextualMessage.isNotEmpty) ...[
                    _SectionTitle(title: 'Message'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getMessageBgColor(exhibition.status),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getMessageBorderColor(exhibition.status),
                        ),
                      ),
                      child: Text(
                        exhibition.contextualMessage,
                        style: GoogleFonts.jost(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _getMessageTextColor(exhibition.status),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Directions Button (for current exhibitions)
                  if (exhibition.isCurrent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openDirections(exhibition),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_outlined),
                            const SizedBox(width: 8),
                            Text(
                              'Get Directions',
                              style: GoogleFonts.jost(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(start)} – ${formatter.format(end)}';
  }

  Future<void> _openDirections(ExhibitionModel exhibition) async {
    final address = exhibition.address.isEmpty
        ? exhibition.location
        : exhibition.address;
    if (address.isEmpty) return;

    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getMessageBgColor(ExhibitionStatus status) {
    switch (status) {
      case ExhibitionStatus.current:
        if (exhibition.isLastDay) {
          return const Color(0xFFFFEAEA);
        }
        return const Color(0xFFEBF7FF);
      case ExhibitionStatus.future:
        return const Color(0xFFEBF7FF);
      case ExhibitionStatus.past:
        return Colors.grey[100]!;
    }
  }

  Color _getMessageBorderColor(ExhibitionStatus status) {
    switch (status) {
      case ExhibitionStatus.current:
        if (exhibition.isLastDay) {
          return const Color(0xFFDC2626).withValues(alpha: 0.2);
        }
        return const Color(0xFF1E40AF).withValues(alpha: 0.2);
      case ExhibitionStatus.future:
        return const Color(0xFF1E40AF).withValues(alpha: 0.2);
      case ExhibitionStatus.past:
        return Colors.grey[300]!;
    }
  }

  Color _getMessageTextColor(ExhibitionStatus status) {
    switch (status) {
      case ExhibitionStatus.current:
        if (exhibition.isLastDay) {
          return const Color(0xFFDC2626);
        }
        return const Color(0xFF1E40AF);
      case ExhibitionStatus.future:
        return const Color(0xFF1E40AF);
      case ExhibitionStatus.past:
        return Colors.grey[700]!;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBrown),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.jost(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBrown.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }
}
