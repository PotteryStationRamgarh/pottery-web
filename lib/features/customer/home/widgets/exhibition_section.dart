import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/config_provider.dart';
import '../../widgets/image_placeholder.dart';

/// ExhibitionSection — shows the active exhibition info.
/// Content comes entirely from Firestore app_config/exhibition.
///
/// Handles 4 states automatically:
/// 1. isActive: false       → section hidden entirely
/// 2. Before startDate      → shows upcomingMessage banner
/// 3. On endDate (last day) → shows lastDayMessage banner
/// 4. After endDate         → shows thankYouMessage banner
/// 5. During exhibition     → shows full info: image, location, dates, times
///
/// Desktop: image left (42%) | details right (58%)
/// Mobile:  image on top, details below
class ExhibitionSection extends StatelessWidget {
  const ExhibitionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final exhibition = context.watch<ConfigProvider>().exhibition;
    final isMobile   = MediaQuery.of(context).size.width < 768;

    // We NO LONGER hide if exhibition is not active — per user request to always show sections for structural consistency.
    // if (!exhibition.isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      // Slightly warmer background than hero — creates visual separation
      color: const Color(0xFFF7F3EE),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical:   isMobile ? 56 : 96,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: isMobile
            ? _buildMobile(context, exhibition)
            : _buildDesktop(context, exhibition),
      ),
    );
  }

  // ─────────────────────────────────────────
  // DESKTOP
  // ─────────────────────────────────────────

  Widget _buildDesktop(BuildContext context, dynamic exhibition) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // Image — 42%
        Expanded(
          flex: 42,
          child: _buildImage(exhibition),
        ),

        const SizedBox(width: 72),

        // Details — 58%
        Expanded(
          flex: 58,
          child: _buildDetails(exhibition, isMobile: false),
        ),

      ],
    );
  }

  // ─────────────────────────────────────────
  // MOBILE
  // ─────────────────────────────────────────

  Widget _buildMobile(BuildContext context, dynamic exhibition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(exhibition),
        const SizedBox(height: 36),
        _buildDetails(exhibition, isMobile: true),
      ],
    );
  }

  // ─────────────────────────────────────────
  // IMAGE
  // ─────────────────────────────────────────

  Widget _buildImage(dynamic exhibition) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.divider.withOpacity(0.3),
        // Asymmetric corners — editorial feel
        borderRadius: const BorderRadius.only(
          topRight:    Radius.circular(64),
          bottomLeft:  Radius.circular(64),
          topLeft:     Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: exhibition.imageUrl.isNotEmpty
            ? Image.network(
                exhibition.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const ImagePlaceholder(
                  aspectRatio: 1.0,
                  icon: Icons.photo_outlined,
                ),
              )
            : const ImagePlaceholder(
                aspectRatio: 1.0,
                icon: Icons.photo_outlined,
              ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // DETAILS
  // ─────────────────────────────────────────

  Widget _buildDetails(dynamic exhibition, {required bool isMobile}) {
    final message    = exhibition.contextualMessage as String;
    final hasMessage = message.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Section label
        Text(
          'EXHIBITION',
          style: GoogleFonts.jost(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryBrown.withOpacity(0.55),
            letterSpacing: 3.5,
          ),
        ),

        const SizedBox(height: 12),

        // Exhibition title
        Text(
          exhibition.title.isNotEmpty ? exhibition.title : 'Upcoming Exhibition',
          style: GoogleFonts.playfairDisplay(
            fontSize: isMobile ? 28 : 38,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 24),

        // Contextual message banner — upcoming / last day / thank you
        if (hasMessage) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryBrown.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 15,
                  color: AppTheme.primaryBrown,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.jost(
                      fontSize: 13,
                      color: AppTheme.primaryBrown,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Location row
        _InfoRow(
          icon: Icons.location_on_outlined,
          title: exhibition.location.isNotEmpty ? exhibition.location : 'Location to be announced',
          subtitle: exhibition.address.isNotEmpty ? exhibition.address : 'Ramgarh, Jharkhand',
        ),

        const SizedBox(height: 16),

        // Date range row
        if (exhibition.startDate != null && exhibition.endDate != null)
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: _formatDateRange(
              exhibition.startDate!,
              exhibition.endDate!,
            ),
          ),

        const SizedBox(height: 16),

        // Time row
        if (exhibition.displayTime.isNotEmpty)
          _InfoRow(
            icon: Icons.access_time_outlined,
            title: exhibition.displayTime,
            subtitle: '${exhibition.openTime} — ${exhibition.closeTime}',
          ),

        const SizedBox(height: 32),

      ],
    );
  }

  // ─────────────────────────────────────────
  // DATE FORMATTER
  // ─────────────────────────────────────────

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    // Compact format if same month and year: "1–15 Apr 2026"
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${end.day} ${months[start.month - 1]} ${start.year}';
    }

    return '${start.day} ${months[start.month - 1]} – '
        '${end.day} ${months[end.month - 1]} ${end.year}';
  }
}

// ─────────────────────────────────────────
// INFO ROW — icon + title + optional subtitle
// ─────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Icon inside soft circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryBrown.withOpacity(0.07),
          ),
          child: Icon(
            icon,
            size: 15,
            color: AppTheme.primaryBrown,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),

      ],
    );
  }
}