import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes.dart';
import '../../../../core/services/auth_gate_service.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../features/auth/auth_service.dart';
import 'notification_bell.dart';

/// NavBar — fixed glass effect navigation bar at the top of the home screen.
///
/// Desktop layout:
/// Logo | COLLECTIONS | ABOUT | CONTACT | account/cart actions
///
/// Mobile layout:
/// Logo | hamburger icon → opens NavDrawer from the right
///
/// "Collections" is always the active item since this is the home screen.
/// Profile icon opens a dropdown with user email + sign out option.
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  // Fixed height for the nav bar — used by Scaffold appBar
  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    final config = context.watch<ConfigProvider>();
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        // Slightly transparent warm white — glass effect
        color: AppTheme.background.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.divider.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? _MobileNav(config: config, currentRoute: currentRoute)
          : _DesktopNav(config: config, currentRoute: currentRoute),
    );
  }
}

// ─────────────────────────────────────────
// DESKTOP NAV
// ─────────────────────────────────────────

class _DesktopNav extends StatelessWidget {
  final ConfigProvider config;
  final String? currentRoute;
  const _DesktopNav({required this.config, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final canGoBack =
        Navigator.canPop(context) && currentRoute != Routes.customerHome;

    // Dynamic spacing and padding based on available width
    // Helps prevent "Overflow" errors on smaller desktop screens
    final double horizontalPadding = width < 1200 ? 24 : 48;
    final double itemSpacing = width < 1200 ? 20 : 36;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          // Brand logo — text fallback if no logoUrl in Firestore
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canGoBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  color: AppTheme.textLight,
                  onPressed: () => Navigator.maybePop(context),
                ),
              AppLogo(
                logoUrl: config.branding.logoUrl,
                appName: config.branding.appName,
                size: 28,
              ),
            ],
          ),

          SizedBox(width: width < 1200 ? 20 : 32),

          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavItem(
                      label: 'Collections',
                      isActive: currentRoute == Routes.customerHome,
                      onTap: () => _openRoute(context, Routes.customerHome),
                    ),
                    SizedBox(width: itemSpacing),

                    // Workshop — Coming Soon snackbar
                    _NavItem(
                      label: 'Workshop',
                      onTap: () => _showComingSoon(context),
                    ),
                    SizedBox(width: itemSpacing),

                    // About — navigates to dedicated About Us page
                    _NavItem(
                      label: 'About',
                      isActive: currentRoute == Routes.aboutUs,
                      onTap: () => _openRoute(context, Routes.aboutUs),
                    ),
                    SizedBox(width: itemSpacing),

                    // Contact — opens a dialog with contact info from Firestore
                    _NavItem(
                      label: 'Contact',
                      onTap: () => _showContact(context, config),
                    ),
                    SizedBox(width: itemSpacing),



                    SizedBox(width: width < 1200 ? 16 : 28),

                    // Search icon
                    IconButton(
                      icon: const Icon(Icons.search, size: 24),
                      color: AppTheme.textLight,
                      onPressed: () => _openRoute(context, Routes.categories),
                    ),

                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 24),
                      color: AppTheme.textLight,
                      onPressed: () => _openRoute(context, Routes.wishlist),
                    ),

                    const NotificationBell(),

                    const _CartButton(),

                    // Profile icon — now routes to MyAccount
                    IconButton(
                      icon: const Icon(Icons.person_outline, size: 24),
                      color: AppTheme.textLight,
                      onPressed: () {
                        if (FirebaseAuth.instance.currentUser == null) {
                          AuthGateService.requireLogin(
                            context,
                            routeName: Routes.myAccount,
                          );
                          return;
                        }
                        Navigator.pushNamed(context, Routes.myAccount);
                      },
                    ),

                    SizedBox(width: width < 1200 ? 12 : 20),
                  ],
                ),
              ),
            ),
          ),
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
  final String? currentRoute;
  const _MobileNav({required this.config, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (currentRoute != Routes.customerHome && Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              color: AppTheme.textDark,
              onPressed: () => Navigator.maybePop(context),
            ),
          // Brand logo
          AppLogo(
            logoUrl: config.branding.logoUrl,
            appName: config.branding.appName,
            size: 24,
          ),

          const Spacer(),

          // Search icon
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            color: AppTheme.textDark,
            onPressed: () => _openRoute(context, Routes.categories),
          ),

          // Cart icon
          const _CartButton(isMobile: true),

          IconButton(
            icon: const Icon(Icons.favorite_border, size: 24),
            color: AppTheme.textDark,
            onPressed: () => _openRoute(context, Routes.wishlist),
          ),

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
// CART BUTTON WITH BADGE
// ─────────────────────────────────────────

class _CartButton extends StatelessWidget {
  final bool isMobile;
  const _CartButton({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    context.watch<CartProvider>();

    return IconButton(
      icon: Icon(Icons.shopping_bag_outlined, size: isMobile ? 22 : 20),
      color: isMobile ? AppTheme.textDark : AppTheme.textLight,
      onPressed: () => _openRoute(context, Routes.cart),
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
                isActive:
                    ModalRoute.of(context)?.settings.name ==
                    Routes.customerHome,
                onTap: () {
                  Navigator.pop(context);
                  _openRoute(context, Routes.customerHome);
                },
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
                isActive:
                    ModalRoute.of(context)?.settings.name == Routes.aboutUs,
                onTap: () {
                  Navigator.pop(context);
                  _openRoute(context, Routes.aboutUs);
                },
              ),
              _DrawerItem(
                label: 'Contact',
                onTap: () {
                  Navigator.pop(context);
                  _showContact(context, config);
                },
              ),

              _DrawerItem(
                label: 'Wishlist',
                onTap: () {
                  Navigator.pop(context);
                  _openRoute(context, Routes.wishlist);
                },
              ),
              _DrawerItem(
                label: 'My Account',
                onTap: () {
                  Navigator.pop(context);
                  if (FirebaseAuth.instance.currentUser == null) {
                    AuthGateService.requireLogin(
                      context,
                      routeName: Routes.myAccount,
                    );
                    return;
                  }
                  _openRoute(context, Routes.myAccount);
                },
              ),

              const Spacer(),

              // Sign out at bottom of drawer
              _DrawerItem(
                label: FirebaseAuth.instance.currentUser == null
                    ? 'Sign In'
                    : 'Sign Out',
                icon: FirebaseAuth.instance.currentUser == null
                    ? Icons.login
                    : Icons.logout,
                onTap: () async {
                  Navigator.pop(context);
                  if (FirebaseAuth.instance.currentUser == null) {
                    Navigator.pushNamed(context, Routes.signin);
                    return;
                  }
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.customerHome,
                    );
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
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: highlight ? AppTheme.primaryBrown : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.jost(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              color: highlight ? AppTheme.primaryBrown : AppTheme.textLight,
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
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 2.5,
                color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DIALOGS — About and Contact
// ─────────────────────────────────────────

// About dialog removed in favor of About Page

void _showContact(BuildContext context, ConfigProvider config) {
  final c = config.contact;
  _showInfoDialog(
    context,
    title: 'Contact Us',
    content: [
      if (c.address.isNotEmpty) '📍  ${c.address}',
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
        style: GoogleFonts.jost(fontSize: 13, color: AppTheme.white),
      ),
      backgroundColor: AppTheme.primaryBrown,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ),
  );
}

void _openRoute(BuildContext context, String routeName, {Object? arguments}) {
  final currentRoute = ModalRoute.of(context)?.settings.name;
  if (currentRoute == routeName) {
    return;
  }

  Navigator.pushNamed(context, routeName, arguments: arguments);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
