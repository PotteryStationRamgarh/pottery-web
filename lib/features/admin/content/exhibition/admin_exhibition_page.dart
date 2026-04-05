import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/repositories/exhibition_repository.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../models/exhibition.dart';

class AdminExhibitionPage extends StatefulWidget {
  const AdminExhibitionPage({super.key});

  @override
  State<AdminExhibitionPage> createState() => _AdminExhibitionPageState();
}

class _AdminExhibitionPageState extends State<AdminExhibitionPage> {
  // Mode: 'list' or 'form'
  String _mode = 'list';
  bool _isLoading = true;
  bool _isSaving = false;

  List<Exhibition> _allExhibitions = [];
  List<Exhibition> _filteredExhibitions = [];
  String _searchQuery = '';

  // Form State
  Exhibition? _editingExhibition;
  late TextEditingController _titleCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _openTimeCtrl;
  late TextEditingController _closeTimeCtrl;
  late TextEditingController _displayTimeCtrl;
  late TextEditingController _upcomingMsgCtrl;
  late TextEditingController _lastDayMsgCtrl;
  late TextEditingController _thankYouMsgCtrl;
  late TextEditingController _searchCtrl;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = false;
  String? _currentImageUrl;
  Uint8List? _newImageBytes;

  final ImagePicker _picker = ImagePicker();
  final MediaService _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _openTimeCtrl = TextEditingController();
    _closeTimeCtrl = TextEditingController();
    _displayTimeCtrl = TextEditingController();
    _upcomingMsgCtrl = TextEditingController();
    _lastDayMsgCtrl = TextEditingController();
    _thankYouMsgCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
    _loadExhibitions();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    _displayTimeCtrl.dispose();
    _upcomingMsgCtrl.dispose();
    _lastDayMsgCtrl.dispose();
    _thankYouMsgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> _loadExhibitions() async {
    setState(() => _isLoading = true);
    try {
      final list = await ExhibitionRepository.getAll(forceRefresh: true);
      // Filter: Show only exhibitions where endDate is within last 30 days OR in future
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      _allExhibitions = list.where((e) {
        if (e.endDate == null) return true;
        return e.endDate!.isAfter(cutoff);
      }).toList();
      _applyFilter();
    } catch (e) {
      _showSnackbar('Error loading exhibitions: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredExhibitions = List.from(_allExhibitions);
      } else {
        _filteredExhibitions = _allExhibitions.where((e) {
          final query = _searchQuery.toLowerCase();
          return e.title.toLowerCase().contains(query) ||
              e.location.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteExhibition(Exhibition exhibition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exhibition?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ExhibitionRepository.deleteExhibition(exhibition.id);
        if (mounted) context.read<AppRefreshProvider>().invalidateAll();
        _showSnackbar('Exhibition deleted');
        _loadExhibitions();
      } catch (e) {
        _showSnackbar('Delete failed: $e', isError: true);
      }
    }
  }

  // ── MODE SWITCH ───────────────────────────────────────────────────────────

  void _showForm([Exhibition? exhibition]) {
    _editingExhibition = exhibition;
    if (exhibition != null) {
      _titleCtrl.text = exhibition.title;
      _locationCtrl.text = exhibition.location;
      _addressCtrl.text = exhibition.address;
      _startDate = exhibition.startDate;
      _endDate = exhibition.endDate;
      _openTimeCtrl.text = exhibition.openTime;
      _closeTimeCtrl.text = exhibition.closeTime;
      _displayTimeCtrl.text = exhibition.displayTime;
      _upcomingMsgCtrl.text = exhibition.upcomingMessage;
      _lastDayMsgCtrl.text = exhibition.lastDayMessage;
      _thankYouMsgCtrl.text = exhibition.thankYouMessage;
      _isActive = exhibition.isActive;
      _currentImageUrl = exhibition.imageUrl.isNotEmpty
          ? exhibition.imageUrl
          : null;
    } else {
      _titleCtrl.clear();
      _locationCtrl.clear();
      _addressCtrl.clear();
      _startDate = null;
      _endDate = null;
      _openTimeCtrl.clear();
      _closeTimeCtrl.clear();
      _displayTimeCtrl.clear();
      _upcomingMsgCtrl.clear();
      _lastDayMsgCtrl.clear();
      _thankYouMsgCtrl.clear();
      _isActive = false;
      _currentImageUrl = null;
    }
    _newImageBytes = null; // Still nullable bytes
    setState(() => _mode = 'form');
  }

  void _showList() {
    setState(() => _mode = 'list');
    _loadExhibitions();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _saveExhibition() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackbar('Title is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      String imageUrl = _currentImageUrl ?? '';
      final docId = _editingExhibition?.id ?? '';

      if (_newImageBytes != null) {
        final pathSegment = docId.isNotEmpty
            ? docId
            : 'new_${DateTime.now().millisecondsSinceEpoch}';
        final urls = await _mediaService.uploadImages(
          docId: pathSegment,
          pathPrefix: 'exhibition',
          files: [_newImageBytes!],
        );
        imageUrl = urls.first;
      }

      final exhibition = Exhibition(
        id: docId,
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        openTime: _openTimeCtrl.text.trim(),
        closeTime: _closeTimeCtrl.text.trim(),
        displayTime: _displayTimeCtrl.text.trim(),
        imageUrl: imageUrl,
        isActive: _isActive,
        thankYouMessage: _thankYouMsgCtrl.text.trim(),
        lastDayMessage: _lastDayMsgCtrl.text.trim(),
        upcomingMessage: _upcomingMsgCtrl.text.trim(),
      );

      await ExhibitionRepository.save(exhibition);
      if (mounted) context.read<AppRefreshProvider>().invalidateAll();
      _showSnackbar('Exhibition saved successfully');
      _showList();
    } catch (e) {
      _showSnackbar('Error saving exhibition: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── IMAGE ─────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newImageBytes = bytes);
    }
  }

  // ── DATE PICKER ───────────────────────────────────────────────────────────

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryBrown),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _mode == 'list' ? _buildListView() : _buildFormView(),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => _showForm(),
      icon: const Icon(Icons.add),
      label: const Text('Add Exhibition'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── LIST VIEW ─────────────────────────────────────────────────────────────

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(32),
          child: LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrowHeader = ResponsiveBreakpoints.isMobileWidth(
                headerConstraints.maxWidth,
              );
              return isNarrowHeader
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exhibition Management',
                          style: AppTheme.headingLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildAddButton(),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Exhibition Management',
                            style: AppTheme.headingLarge,
                          ),
                        ),
                        _buildAddButton(),
                      ],
                    );
            },
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              _searchQuery = val;
              _applyFilter();
            },
            decoration:
                AppTheme.inputDecoration(
                  label: 'Search exhibitions...',
                  hint: 'Search by title or location',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textLight,
                  ),
                ),
          ),
        ),

        const SizedBox(height: 24),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredExhibitions.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  itemCount: _filteredExhibitions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildExhibitionCard(_filteredExhibitions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No exhibitions yet. Add your first exhibition.'
                : 'No exhibitions match your search.',
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: () => _showForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Exhibition'),
            ),
        ],
      ),
    );
  }

  Widget _buildExhibitionCard(Exhibition exhibition) {
    final status = _determineStatus(exhibition);
    final statusColor = _getStatusColor(status);
    final dateRange = _formatDateRange(
      exhibition.startDate,
      exhibition.endDate,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = ResponsiveBreakpoints.isMobileWidth(
            constraints.maxWidth,
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    image: exhibition.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(exhibition.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: exhibition.imageUrl.isEmpty
                      ? const Icon(Icons.image, color: AppTheme.greyPlaceholder)
                      : null,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exhibition.title,
                        style: AppTheme.headingMedium.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        exhibition.location,
                        style: AppTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateRange,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status Badge (Hide text if very narrow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (!isNarrow) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.primaryBrown,
                    ),
                    onPressed: () => _showForm(exhibition),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteExhibition(exhibition),
                    tooltip: 'Delete',
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit')
                        _showForm(exhibition);
                      else if (val == 'delete')
                        _deleteExhibition(exhibition);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _determineStatus(Exhibition e) {
    if (!e.isActive) return 'Inactive';
    final now = DateTime.now();
    if (e.startDate != null && e.startDate!.isAfter(now)) return 'Upcoming';
    if (e.endDate != null && e.endDate!.isBefore(now)) return 'Past';
    return 'Active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppTheme.successGreen;
      case 'Upcoming':
        return AppTheme.primaryBrown;
      case 'Past':
        return AppTheme.textLight;
      default:
        return Colors.grey;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No dates set';
    final fmt = DateFormat('d MMM');
    final year = start.year;
    return '${fmt.format(start)} – ${fmt.format(end)} $year';
  }

  // ── FORM VIEW ─────────────────────────────────────────────────────────────

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = ResponsiveBreakpoints.isMobileWidth(
                constraints.maxWidth,
              );
              return isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _showList,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to List'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _editingExhibition == null
                              ? 'Add Exhibition'
                              : 'Edit: ${_editingExhibition!.title}',
                          style: AppTheme.headingLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveExhibition,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save Exhibition'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        TextButton.icon(
                          onPressed: _showList,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to List'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryBrown,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _editingExhibition == null
                                ? 'Add Exhibition'
                                : 'Edit: ${_editingExhibition!.title}',
                            style: AppTheme.headingLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveExhibition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Exhibition'),
                        ),
                      ],
                    );
            },
          ),

          const SizedBox(height: 32),

          // Active Toggle
          SwitchListTile(
            title: Text('Is Active', style: AppTheme.headingMedium),
            subtitle: Text(
              'Show this exhibition on the customer home screen',
              style: AppTheme.bodySmall,
            ),
            activeColor: AppTheme.successGreen,
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          // Core Info + Dates
          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = !ResponsiveBreakpoints.isDesktopWidth(
                c.maxWidth,
              );
              return isNarrow
                  ? Column(
                      children: [
                        _buildSection('Core Info', [
                          _buildField('Title', _titleCtrl),
                          const SizedBox(height: 16),
                          _buildField('Location (Short)', _locationCtrl),
                          const SizedBox(height: 16),
                          _buildField(
                            'Full Address',
                            _addressCtrl,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            'Display Time (e.g. "10am – 6pm")',
                            _displayTimeCtrl,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSection('Dates & Image', [
                          LayoutBuilder(
                            builder: (context, c2) {
                              return c2.maxWidth < 400
                                  ? Column(
                                      children: [
                                        _buildDateBtn(
                                          'Start Date',
                                          _startDate,
                                          () => _selectDate(context, true),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDateBtn(
                                          'End Date',
                                          _endDate,
                                          () => _selectDate(context, false),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _buildDateBtn(
                                            'Start Date',
                                            _startDate,
                                            () => _selectDate(context, true),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildDateBtn(
                                            'End Date',
                                            _endDate,
                                            () => _selectDate(context, false),
                                          ),
                                        ),
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, c2) {
                              return c2.maxWidth < 400
                                  ? Column(
                                      children: [
                                        _buildField('Open Time', _openTimeCtrl),
                                        const SizedBox(height: 16),
                                        _buildField(
                                          'Close Time',
                                          _closeTimeCtrl,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _buildField(
                                            'Open Time',
                                            _openTimeCtrl,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildField(
                                            'Close Time',
                                            _closeTimeCtrl,
                                          ),
                                        ),
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildImageCard(
                            'Exhibition Image',
                            _newImageBytes,
                            _currentImageUrl,
                            _pickImage,
                          ),
                        ]),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSection('Core Info', [
                            _buildField('Title', _titleCtrl),
                            const SizedBox(height: 16),
                            _buildField('Location (Short)', _locationCtrl),
                            const SizedBox(height: 16),
                            _buildField(
                              'Full Address',
                              _addressCtrl,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              'Display Time (e.g. "10am – 6pm")',
                              _displayTimeCtrl,
                            ),
                          ]),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildSection('Dates & Image', [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateBtn(
                                    'Start Date',
                                    _startDate,
                                    () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateBtn(
                                    'End Date',
                                    _endDate,
                                    () => _selectDate(context, false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    'Open Time',
                                    _openTimeCtrl,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildField(
                                    'Close Time',
                                    _closeTimeCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildImageCard(
                              'Exhibition Image',
                              _newImageBytes,
                              _currentImageUrl,
                              _pickImage,
                            ),
                          ]),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Messages
          _buildSection('Dynamic Messages', [
            _buildField(
              'Upcoming Message (before exhibition starts)',
              _upcomingMsgCtrl,
            ),
            const SizedBox(height: 16),
            _buildField('Last Day Message', _lastDayMsgCtrl),
            const SizedBox(height: 16),
            _buildField(
              'Thank You Message (after exhibition ends)',
              _thankYouMsgCtrl,
            ),
          ]),
        ],
      ),
    );
  }

  // ── FORM HELPERS ──────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(
            label: label,
            hint: 'Enter $label',
          ),
        ),
      ],
    );
  }

  Widget _buildDateBtn(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Select Date',
                  style: AppTheme.bodyLarge.copyWith(
                    color: date != null
                        ? AppTheme.textDark
                        : AppTheme.greyPlaceholder,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(
    String title,
    Uint8List? localBytes,
    String? networkUrl,
    VoidCallback onPick,
  ) {
    final hasImage =
        localBytes != null || (networkUrl != null && networkUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
              image: hasImage
                  ? DecorationImage(
                      image: localBytes != null
                          ? MemoryImage(localBytes) as ImageProvider
                          : NetworkImage(networkUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppTheme.greyPlaceholder,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload Image',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.successGreen,
      ),
    );
  }
}
