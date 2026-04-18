import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/exhibition_model.dart';
import '../../../../core/providers/exhibition_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/exhibition_card.dart';
import 'exhibition_detail_screen.dart';

/// Exhibition listing screen
/// Displays all exhibitions sorted by priority: Current → Future → Past
class ExhibitionScreen extends StatelessWidget {
  const ExhibitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exhibitions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
      ),
      body: StreamBuilder<List<ExhibitionModel>>(
        stream: provider.allExhibitionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load exhibitions',
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.jost(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          final exhibitions = snapshot.data ?? [];

          if (exhibitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exhibitions available',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for upcoming events',
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group exhibitions by status
          final current = exhibitions.where((e) => e.isCurrent).toList();
          final future = exhibitions.where((e) => e.isFuture).toList();
          final past = exhibitions.where((e) => e.isPast).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current exhibitions section
              if (current.isNotEmpty) ...[
                _SectionHeader(title: 'Live Now', count: current.length),
                ...current
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ExhibitionCard(
                          exhibition: e,
                          onTap: () => _navigateToDetail(context, e),
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
              ],
              // Future exhibitions section
              if (future.isNotEmpty) ...[
                _SectionHeader(title: 'Upcoming', count: future.length),
                ...future
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ExhibitionCard(
                          exhibition: e,
                          onTap: () => _navigateToDetail(context, e),
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
              ],
              // Past exhibitions section
              if (past.isNotEmpty) ...[
                _SectionHeader(title: 'Past Events', count: past.length),
                ...past
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ExhibitionCard(
                          exhibition: e,
                          onTap: () => _navigateToDetail(context, e),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, ExhibitionModel exhibition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExhibitionDetailScreen(exhibition: exhibition),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.jost(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
