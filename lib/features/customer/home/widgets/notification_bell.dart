import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/repositories/notification_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/app_notification.dart';

/// Notification bell icon for the customer NavBar.
/// Shows an unread count badge and opens a slide-in drawer panel.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final count = await NotificationRepository.getUnreadCount(uid);
    if (mounted) setState(() => _unreadCount = count);
  }

  void _openPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationPanel(onRead: _refreshCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: AppTheme.textLight,
          onPressed: _openPanel,
          tooltip: 'Notifications',
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 6,
            child: GestureDetector(
              onTap: _openPanel,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.terracotta,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// NOTIFICATION PANEL (slide-up modal sheet)
// ─────────────────────────────────────────────────────────────────
class _NotificationPanel extends StatefulWidget {
  final VoidCallback onRead;
  const _NotificationPanel({required this.onRead});

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    await NotificationRepository.markAllReadForUser(_uid);
    widget.onRead();
    if (mounted) setState(() => _markingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                if (_markingAll)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBrown,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Notification list ──────────────────────────
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: NotificationRepository.watchForUser(_uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBrown,
                    ),
                  );
                }
                final notifications = snap.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 56,
                          color: AppTheme.divider,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.jost(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final n = notifications[i];
                    return _NotificationTile(
                      notification: n,
                      onTap: () async {
                        if (!n.isRead) {
                          await NotificationRepository.markRead(n.id);
                          widget.onRead();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final d = n.createdAt;
    final now = DateTime.now();
    final diff = now.difference(d);
    String timeAgo;
    if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = '${diff.inDays}d ago';
    }

    final icon = _iconForCategory(n.category);
    final iconColor = _colorForCategory(n.category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: n.isRead
              ? Colors.transparent
              : AppTheme.primaryBrown.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.jost(
                            fontSize: 13,
                            fontWeight:
                                n.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.terracotta,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: GoogleFonts.jost(
                      fontSize: 10,
                      color: AppTheme.textLight.withValues(alpha: 0.7),
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

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'exhibition':
        return Icons.event_outlined;
      case 'alert':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'order':
        return AppTheme.successGreen;
      case 'promo':
        return AppTheme.terracotta;
      case 'exhibition':
        return AppTheme.primaryBrown;
      case 'alert':
        return Colors.orange;
      default:
        return AppTheme.primaryBrown;
    }
  }
}
