import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/exhibition_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets/image_placeholder.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    if (exhibition.title.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F3EE),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 56 : 96,
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
        color: AppTheme.divider.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(64),
          bottomLeft: Radius.circular(64),
          topLeft: Radius.circular(12),
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
                errorBuilder: (_, _, _) => const ImagePlaceholder(
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

  Widget _buildDetails(dynamic exhibition, {required bool isMobile}) {
    final message = exhibition.contextualMessage as String;
    final hasMessage = message.isNotEmpty;

    final now = DateTime.now();
    final bool isUpcoming =
        exhibition.startDate != null && exhibition.startDate!.isAfter(now);
    final bool isPast =
        exhibition.endDate != null && exhibition.endDate!.isBefore(now);
    final bool isActive = !isUpcoming && !isPast;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EXHIBITION',
              style: GoogleFonts.jost(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBrown.withValues(alpha: 0.55),
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(width: 12),
            if (isUpcoming)
              _StatusBadge(text: 'COMING SOON', color: AppTheme.primaryBrown),
            if (isPast)
              _StatusBadge(text: 'THANK YOU', color: AppTheme.textLight),
            if (isActive)
              _StatusBadge(text: 'LIVE NOW', color: AppTheme.successGreen),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          exhibition.title.isNotEmpty
              ? exhibition.title
              : 'Upcoming Exhibition',
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
              color: AppTheme.primaryBrown.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryBrown.withValues(alpha: 0.18),
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

        _InfoRow(
          icon: Icons.location_on_outlined,
          title: exhibition.location.isNotEmpty
              ? exhibition.location
              : 'Location TBA',
          subtitle: exhibition.address.isNotEmpty ? exhibition.address : null,
        ),
        const SizedBox(height: 16),

        if (exhibition.startDate != null && exhibition.endDate != null) ...[
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: _formatDateRange(exhibition.startDate!, exhibition.endDate!),
          ),
          const SizedBox(height: 16),
        ],

        if (exhibition.displayTime.isNotEmpty)
          _InfoRow(
            icon: Icons.access_time_outlined,
            title: exhibition.displayTime,
            subtitle: '${exhibition.openTime} — ${exhibition.closeTime}',
          ),

        if (isActive) ...[
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final address = exhibition.address.isNotEmpty
                  ? exhibition.address
                  : exhibition.location;
              if (address.isEmpty) return;
              final encoded = Uri.encodeComponent(address);
              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$encoded',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Visit Now'),
          ),
        ],
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    String f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${f(start)} – ${f(end)}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _InfoRow({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryBrown.withValues(alpha: 0.07),
          ),
          child: Icon(icon, size: 15, color: AppTheme.primaryBrown),
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

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.jost(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
