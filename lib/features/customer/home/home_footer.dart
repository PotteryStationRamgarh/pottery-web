import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/config_provider.dart';

/// HomeFooter — bottom section of the customer home screen.
/// Shows brand name, nav links, social links, copyright.
///
/// All content comes from ConfigProvider:
/// branding → appName
/// contact  → address, email, phone
/// content  → aboutUs, privacyPolicy, termsConditions
/// social   → instagramUrl, facebookUrl
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final config   = context.watch<ConfigProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: AppTheme.footerBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical:   isMobile ? 48 : 64,
      ),
      child: Column(
        children: [

          // Brand name — italic serif
          Text(
            config.branding.appName.isNotEmpty
                ? config.branding.appName
                : 'Pottery Station',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppTheme.textDark,
            ),
          ),

          const SizedBox(height: 32),

          // Footer links — wraps on mobile
          Wrap(
            spacing:    isMobile ? 20 : 48,
            runSpacing: 16,
            alignment:  WrapAlignment.center,
            children: [

              _FooterLink(
                label: 'Instagram',
                onTap: () => _openSocial(context, config.social.instagramUrl),
              ),
              _FooterLink(
                label: 'Facebook',
                onTap: () => _openSocial(context, config.social.facebookUrl),
              ),
              _FooterLink(
                label: 'Contact',
                onTap: () => _showContact(context, config),
              ),
              _FooterLink(
                label: 'About Us',
                onTap: () => _showTextDialog(
                  context,
                  title:   'About Us',
                  content: config.content.aboutUs,
                ),
              ),
              _FooterLink(
                label: 'Privacy Policy',
                onTap: () => _showTextDialog(
                  context,
                  title:   'Privacy Policy',
                  content: config.content.privacyPolicy,
                ),
              ),
              _FooterLink(
                label: 'Terms',
                onTap: () => _showTextDialog(
                  context,
                  title:   'Terms & Conditions',
                  content: config.content.termsConditions,
                ),
              ),

            ],
          ),

          const SizedBox(height: 40),

          Divider(color: AppTheme.divider.withOpacity(0.5)),

          const SizedBox(height: 24),

          // Copyright line
          Text(
            '© ${DateTime.now().year} '
            '${config.branding.appName.isNotEmpty ? config.branding.appName : 'Pottery Station Ramgarh'}.'
            ' Hand-thrown in small batches.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: AppTheme.textLight.withOpacity(0.45),
              letterSpacing: 0.4,
              height: 1.6,
            ),
          ),

        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming soon!',
          style: GoogleFonts.jost(fontSize: 13, color: AppTheme.white),
        ),
        backgroundColor: AppTheme.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openSocial(BuildContext context, String url) {
    if (url.isEmpty || url == 'Coming Soon') {
      _showComingSoon(context);
    } else {
      // In a real production app, use url_launcher package here.
      // For now, we show a success message with the link info
      // or implement web-specific launch if needed.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening $url...',
            style: GoogleFonts.jost(fontSize: 13, color: AppTheme.white),
          ),
          backgroundColor: AppTheme.primaryBrown,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showContact(BuildContext context, ConfigProvider config) {
    final c = config.contact;
    _showTextDialog(
      context,
      title: 'Contact Us',
      content: [
        if (c.address.isNotEmpty)      '📍  ${c.address}',
        if (c.supportEmail.isNotEmpty) '✉️  ${c.supportEmail}',
        if (c.supportPhone.isNotEmpty) '📞  ${c.supportPhone}',
      ].join('\n\n'),
    );
  }

  void _showTextDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth:  520,
            maxHeight: 520,
          ),
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 14),
                Divider(color: AppTheme.divider),
                const SizedBox(height: 14),

                // Scrollable content — aboutUs can be very long
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      content.isNotEmpty ? content : 'Coming soon.',
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.jost(
                        fontSize: 13,
                        color: AppTheme.primaryBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// FOOTER LINK
// ─────────────────────────────────────────

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isHovered
                    ? AppTheme.primaryBrown
                    : AppTheme.transparent,
                width: 1,
              ),
            ),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.jost(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.5,
              color: _isHovered
                  ? AppTheme.primaryBrown
                  : AppTheme.textLight.withOpacity(0.55),
            ),
          ),
        ),
      ),
    );
  }
}