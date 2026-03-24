import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../features/auth/auth_service.dart';

/// NavBar — fixed glass effect navigation bar at the top of the home screen.
///
/// Desktop layout:
/// Logo | COLLECTIONS | ABOUT | CONTACT | profile icon | [GO TO STORE]
///
/// Mobile layout:
/// Logo | hamburger icon → opens NavDrawer from the right
///
/// "Collections" is always the active item since this is the home screen.
/// "Go to Store" shows a coming soon snackbar — feature planned for V2.
/// Profile icon opens a dropdown with user email + sign out option.
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  // Fixed height for the nav bar — used by Scaffold appBar
  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final config   = context.watch<ConfigProvider>();

    return Container(
      height: 72,
      decoration: BoxDecoration(
        // Slightly transparent warm white — glass effect
        color: AppTheme.background.withOpacity(0.88),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.divider.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? _MobileNav(config: config)
          : _DesktopNav(config: config),
    );
  }
}

// ─────────────────────────────────────────
// DESKTOP NAV
// ─────────────────────────────────────────

class _DesktopNav extends StatelessWidget {
  final ConfigProvider config;
  const _DesktopNav({required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [

          // Brand logo — text fallback if no logoUrl in Firestore
          AppLogo(
            logoUrl: config.branding.logoUrl,
            appName: config.branding.appName,
            size: 28,
          ),

          const Spacer(),

          _NavItem(
            label: 'Collections',
            isActive: true,
            onTap: () {},
          ),
          const SizedBox(width: 36),

          // Workshop — Coming Soon snackbar
          _NavItem(
            label: 'Workshop',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(width: 36),

          // About — opens a dialog with aboutUs text from Firestore
          _NavItem(
            label: 'About',
            onTap: () => _showAbout(context, config),
          ),
          const SizedBox(width: 36),

          // Contact — opens a dialog with contact info from Firestore
          _NavItem(
            label: 'Contact',
            onTap: () => _showContact(context, config),
          ),

          const SizedBox(width: 28),

          // Profile icon — dropdown with email + sign out
          _ProfileButton(),

          const SizedBox(width: 20),

          // Go to Store — coming soon snackbar for now
          _StoreButton(),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// MOBILE NAV
// ─────────────────────────────────────────

class _MobileNav extends StatelessWidget {
  final ConfigProvider config;
  const _MobileNav({required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [

          // Brand logo
          AppLogo(
            logoUrl: config.branding.logoUrl,
            appName: config.branding.appName,
            size: 24,
          ),

          const Spacer(),

          // Hamburger — opens the end drawer
          IconButton(
            icon: const Icon(Icons.menu, size: 24),
            color: AppTheme.textDark,
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// MOBILE DRAWER
// Opens from the right when hamburger is tapped
// ─────────────────────────────────────────

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();

    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Logo at top of drawer
              AppLogo(
                logoUrl: config.branding.logoUrl,
                appName: config.branding.appName,
                size: 24,
              ),

              const SizedBox(height: 48),

              _DrawerItem(
                label: 'Collections',
                isActive: true,
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                label: 'Workshop',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context);
                },
              ),
              _DrawerItem(
                label: 'About',
                onTap: () {
                  Navigator.pop(context);
                  _showAbout(context, config);
                },
              ),
              _DrawerItem(
                label: 'Contact',
                onTap: () {
                  Navigator.pop(context);
                  _showContact(context, config);
                },
              ),

              const Spacer(),

              // Go to Store button — full width in drawer
              SizedBox(
                width: double.infinity,
                child: _StoreButton(fullWidth: true),
              ),

              const SizedBox(height: 16),

              // Sign out at bottom of drawer
              _DrawerItem(
                label: 'Sign Out',
                icon: Icons.logout,
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, Routes.signin);
                  }
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// NAV ITEM — desktop link with underline on hover/active
// ─────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isActive || _isHovered;

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
                color: highlight
                    ? AppTheme.primaryBrown
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.jost(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              color: highlight
                  ? AppTheme.primaryBrown
                  : AppTheme.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DRAWER ITEM — mobile nav link
// ─────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const _DrawerItem({
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 10),
            ],
            Text(
              label.toUpperCase(),
              style: GoogleFonts.jost(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 2.5,
                color: isActive
                    ? AppTheme.primaryBrown
                    : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PROFILE BUTTON
// Dropdown with user email + sign out
// ─────────────────────────────────────────

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      color: AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.divider, width: 1),
      ),
      itemBuilder: (_) => [

        // User email — not clickable, just for info
        PopupMenuItem(
          enabled: false,
          child: Text(
            FirebaseAuth.instance.currentUser?.email ?? '',
            style: GoogleFonts.jost(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
        ),

        const PopupMenuDivider(),

        // Sign out option
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 15, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Text(
                'Sign Out',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),

      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await AuthService().logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, Routes.signin);
          }
        }
      },
      // Circle icon button that triggers the dropdown
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.divider,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.person_outline,
          size: 18,
          color: AppTheme.textLight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// STORE BUTTON
// Shows coming soon snackbar — real store is V2
// ─────────────────────────────────────────

class _StoreButton extends StatelessWidget {
  final bool fullWidth;
  const _StoreButton({this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Online store coming soon!',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.primaryBrown,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.primaryBrown,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'GO TO STORE',
          style: GoogleFonts.jost(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DIALOGS — About and Contact
// ─────────────────────────────────────────

void _showAbout(BuildContext context, ConfigProvider config) {
  _showInfoDialog(
    context,
    title: 'About Us',
    content: config.content.aboutUs.isNotEmpty
        ? config.content.aboutUs
        : 'Pottery Station Ramgarh is dedicated to the art of hand-thrown ceramics.',
  );
}

void _showContact(BuildContext context, ConfigProvider config) {
  final c = config.contact;
  _showInfoDialog(
    context,
    title: 'Contact Us',
    content: [
      if (c.address.isNotEmpty)      '📍  ${c.address}',
      if (c.supportEmail.isNotEmpty) '✉️  ${c.supportEmail}',
      if (c.supportPhone.isNotEmpty) '📞  ${c.supportPhone}',
    ].join('\n\n'),
  );
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Workshop section coming soon!',
        style: GoogleFonts.jost(
          fontSize: 13,
          color: AppTheme.white,
        ),
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

void _showInfoDialog(
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Dialog title
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

              // Dialog content — scrollable in case text is long
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      height: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Close button — right aligned
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