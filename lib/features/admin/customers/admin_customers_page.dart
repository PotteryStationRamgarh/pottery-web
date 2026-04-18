import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../core/repositories/order_repository.dart';

/// Admin page to view and search all customers.
/// Queries the 'users' collection where role == 'customer'.
class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String? _expandedUid;
  List<OrderModel> _expandedOrders = [];
  bool _loadingOrders = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .orderBy('createdAt', descending: true)
          .get();
      final customers = snap.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return data;
      }).toList();
      setState(() {
        _allCustomers = customers;
        _filtered = customers;
        _loading = false;
      });
    } catch (e) {
      // createdAt index may not exist yet — fallback to unordered
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'customer')
            .get();
        final customers = snap.docs.map((d) {
          final data = d.data();
          data['uid'] = d.id;
          return data;
        }).toList();
        setState(() {
          _allCustomers = customers;
          _filtered = customers;
          _loading = false;
        });
      } catch (e2) {
        setState(() { _error = e2.toString(); _loading = false; });
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allCustomers
          : _allCustomers.where((c) {
              final name = (c['displayName'] ?? c['name'] ?? '').toLowerCase();
              final email = (c['email'] ?? '').toLowerCase();
              final phone = (c['phone'] ?? '').toLowerCase();
              return name.contains(q) || email.contains(q) || phone.contains(q);
            }).toList();
    });
  }

  Future<void> _toggleExpand(String uid) async {
    if (_expandedUid == uid) {
      setState(() => _expandedUid = null);
      return;
    }
    setState(() {
      _expandedUid = uid;
      _loadingOrders = true;
      _expandedOrders = [];
    });
    try {
      final orders = await OrderRepository.getOrdersByUser(uid);
      setState(() {
        _expandedOrders = orders;
        _loadingOrders = false;
      });
    } catch (_) {
      setState(() => _loadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customers', style: AppTheme.serifHeadingLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${_allCustomers.length} registered customers',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loadCustomers,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Search ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone…',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Content ───────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryBrown,
                  ),
                )
              : _error != null
              ? _buildError()
              : _filtered.isEmpty
              ? _buildEmpty()
              : _buildList(),
        ),
      ],
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 40),
        const SizedBox(height: 12),
        Text('Failed to load customers', style: AppTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _loadCustomers,
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_outline, size: 60, color: AppTheme.divider),
        const SizedBox(height: 16),
        Text(
          _searchCtrl.text.isEmpty ? 'No customers yet' : 'No results found',
          style: AppTheme.bodyMedium,
        ),
      ],
    ),
  );

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CustomerCard(
        data: _filtered[i],
        isExpanded: _expandedUid == _filtered[i]['uid'],
        orders: _expandedOrders,
        loadingOrders: _loadingOrders,
        onTap: () => _toggleExpand(_filtered[i]['uid'] as String),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isExpanded;
  final List<OrderModel> orders;
  final bool loadingOrders;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.data,
    required this.isExpanded,
    required this.orders,
    required this.loadingOrders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] ?? data['name'] ?? 'Unnamed';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';
    final createdAt = data['createdAt'];
    String joined = '';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      joined =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    // Avatar initials
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primaryBrown.withValues(alpha: 0.3)
              : AppTheme.divider.withValues(alpha: 0.5),
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppTheme.primaryBrown.withValues(alpha: 0.12),
                    child: Text(
                      initials,
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.jost(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: GoogleFonts.jost(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        SelectableText(
                          'UID: ${data['uid']}',
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            color: AppTheme.primaryBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Joined date + expand arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (joined.isNotEmpty)
                        Text(
                          'Joined $joined',
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppTheme.textLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Orders Panel ──────────────────────
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER HISTORY',
                    style: GoogleFonts.jost(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (loadingOrders)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBrown,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (orders.isEmpty)
                    Text(
                      'No orders placed yet.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                    )
                  else
                    ...orders.map(
                      (order) => _OrderRow(order: order),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.orderStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '#${order.id.substring(0, 8).toUpperCase()}',
            style: GoogleFonts.jost(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBrown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
              style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              order.orderStatus.replaceAll('_', ' ').toUpperCase(),
              style: GoogleFonts.jost(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${order.totalAmount.toInt()}',
            style: GoogleFonts.jost(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successGreen;
      case 'cancelled':
        return Colors.red;
      case 'in_transit':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return AppTheme.primaryBrown;
    }
  }
}
