import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/exhibition_provider.dart';
import '../../widgets/image_placeholder.dart';

/// ExhibitionSection — shows the active exhibition info on the customer home screen.
/// Data comes from ExhibitionProvider which reads the `exhibition` collection.
///
/// States handled automatically:
/// 1. isActive: false      → section hidden
/// 2. Before startDate     → upcomingMessage banner
/// 3. On endDate (last day)→ lastDayMessage banner
/// 4. After endDate        → thankYouMessage banner
/// 5. During exhibition    → full info card
class ExhibitionSection extends StatelessWidget {
  const ExhibitionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final exhibition = context.watch<ExhibitionProvider>().exhibition;
    final isMobile   = MediaQuery.of(context).size.width < 768;

    if (!exhibition.isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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

  Widget _buildDesktop(BuildContext context, dynamic exhibition) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 42, child: _buildImage(exhibition)),
        const SizedBox(width: 72),
        Expanded(flex: 58, child: _buildDetails(exhibition, isMobile: false)),
      ],
    );
  }

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

  Widget _buildImage(dynamic exhibition) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.divider.withOpacity(0.3),
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
            : const ImagePlaceholder(aspectRatio: 1.0, icon: Icons.photo_outlined),
      ),
    );
  }

  Widget _buildDetails(dynamic exhibition, {required bool isMobile}) {
    final message    = exhibition.contextualMessage as String;
    final hasMessage = message.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXHIBITION',
          style: GoogleFonts.jost(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: AppTheme.primaryBrown.withOpacity(0.55), letterSpacing: 3.5,
          ),
        ),
        const SizedBox(height: 12),
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

        if (hasMessage) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color:        AppTheme.primaryBrown.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: AppTheme.primaryBrown),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: GoogleFonts.jost(
                    fontSize: 13, color: AppTheme.primaryBrown, height: 1.5,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        _InfoRow(
          icon:     Icons.location_on_outlined,
          title:    exhibition.location.isNotEmpty ? exhibition.location : 'Location TBA',
          subtitle: exhibition.address.isNotEmpty  ? exhibition.address  : null,
        ),
        const SizedBox(height: 16),

        if (exhibition.startDate != null && exhibition.endDate != null) ...[
          _InfoRow(
            icon:  Icons.calendar_today_outlined,
            title: _formatDateRange(exhibition.startDate!, exhibition.endDate!),
          ),
          const SizedBox(height: 16),
        ],

        if (exhibition.displayTime.isNotEmpty)
          _InfoRow(
            icon:     Icons.access_time_outlined,
            title:    exhibition.displayTime,
            subtitle: '${exhibition.openTime} — ${exhibition.closeTime}',
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${end.day} ${months[start.month - 1]} ${start.year}';
    }
    return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String?  subtitle;

  const _InfoRow({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryBrown.withOpacity(0.07),
          ),
          child: Icon(icon, size: 15, color: AppTheme.primaryBrown),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.jost(
                fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textDark,
              )),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: GoogleFonts.jost(
                  fontSize: 12, fontWeight: FontWeight.w300, color: AppTheme.textLight,
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }
}