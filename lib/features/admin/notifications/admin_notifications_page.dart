import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../models/app_notification.dart';

/// Admin page to compose and manage notifications.
/// Allows sending to all customers or specific users.
class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications', style: AppTheme.serifHeadingLarge),
              const SizedBox(height: 4),
              Text(
                'Compose and track in-app notifications',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Tabs ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tabCtrl,
            labelStyle: GoogleFonts.jost(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.jost(fontSize: 13),
            labelColor: AppTheme.primaryBrown,
            unselectedLabelColor: AppTheme.textLight,
            indicatorColor: AppTheme.primaryBrown,
            tabs: const [
              Tab(text: 'Compose'),
              Tab(text: 'History'),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Tab content ──────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              _ComposeTab(),
              _HistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// COMPOSE TAB
// ─────────────────────────────────────────────────────────────────
class _ComposeTab extends StatefulWidget {
  const _ComposeTab();

  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _audience = 'all'; // 'all' | 'user'
  String _category = 'general';
  bool _sending = false;
  List<Map<String, dynamic>> _customers = [];

  final List<String> _categories = [
    'general',
    'order',
    'promo',
    'exhibition',
    'alert',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      if (mounted) {
        setState(() {
          _customers = snap.docs.map((d) {
            final data = d.data();
            data['uid'] = d.id;
            return data;
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == 'user' && _recipientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a recipient User ID')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await NotificationRepository.sendNotification(
        audience: _audience,
        recipientId: _audience == 'all' ? '' : _recipientCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        category: _category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _audience == 'all'
                  ? 'Notification sent to all customers ✓'
                  : 'Notification sent to user ✓',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _recipientCtrl.clear();
        setState(() => _audience = 'all');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Audience ─────────────────────────────
            _SectionLabel('Audience'),
            const SizedBox(height: 10),
            Row(
              children: [
                _AudienceChip(
                  label: 'All Customers',
                  icon: Icons.group_outlined,
                  selected: _audience == 'all',
                  onTap: () => setState(() => _audience = 'all'),
                ),
                const SizedBox(width: 12),
                _AudienceChip(
                  label: 'Specific User',
                  icon: Icons.person_outline,
                  selected: _audience == 'user',
                  onTap: () => setState(() => _audience = 'user'),
                ),
              ],
            ),

            if (_audience == 'user') ...[
              const SizedBox(height: 16),
              _SectionLabel('Recipient User'),
              const SizedBox(height: 10),
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => 
                    '${option['name'] ?? option['displayName'] ?? 'Unnamed'} (${option['uid']})',
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  final q = textEditingValue.text.toLowerCase();
                  return _customers.where((c) {
                    final name = (c['name'] ?? c['displayName'] ?? '').toLowerCase();
                    final email = (c['email'] ?? '').toLowerCase();
                    final phone = (c['phone'] ?? '').toLowerCase();
                    return name.contains(q) || email.contains(q) || phone.contains(q);
                  });
                },
                onSelected: (option) {
                  _recipientCtrl.text = option['uid'] as String;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search user by name, email or phone...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) {
                      _recipientCtrl.text = val;
                    },
                    validator: (_) => _recipientCtrl.text.trim().isEmpty ? 'Please select a user' : null,
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // ── Category ─────────────────────────────
            _SectionLabel('Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _categories
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: AppTheme.primaryBrown,
                      labelStyle: TextStyle(
                        color: _category == c
                            ? Colors.white
                            : AppTheme.textDark,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Title ────────────────────────────────
            _SectionLabel('Title'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Short notification title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLength: 80,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),

            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────
            _SectionLabel('Message'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Full notification message…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignLabelWithHint: true,
              ),
              maxLength: 300,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Message is required' : null,
            ),

            const SizedBox(height: 32),

            // ── Send Button ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  _sending ? 'Sending…' : 'Send Notification',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HISTORY TAB
// ─────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationRepository.watchAllForAdmin(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBrown),
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
                Text('No notifications sent yet', style: AppTheme.bodyMedium),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _NotificationHistoryCard(notification: notifications[i]),
        );
      },
    );
  }
}

class _NotificationHistoryCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationHistoryCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final d = n.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final audienceColor =
        n.audience == 'all' ? AppTheme.primaryBrown : AppTheme.terracotta;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: audienceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  n.audience == 'all'
                      ? 'ALL CUSTOMERS'
                      : 'USER: ${n.recipientId.length > 10 ? '${n.recipientId.substring(0, 10)}…' : n.recipientId}',
                  style: GoogleFonts.jost(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: audienceColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  n.category.toUpperCase(),
                  style: GoogleFonts.jost(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: GoogleFonts.jost(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              GestureDetector(
                onTap: () => _confirmDelete(context, n.id),
                child: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.red.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            n.title,
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            n.body,
            style: GoogleFonts.jost(
              fontSize: 13,
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text(
          'This will remove it from the history. Users who have already seen it are unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationRepository.deleteNotification(id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.jost(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textLight,
      letterSpacing: 1,
    ),
  );
}

class _AudienceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AudienceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBrown
              : AppTheme.primaryBrown.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.primaryBrown
                : AppTheme.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.primaryBrown,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.jost(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.primaryBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
