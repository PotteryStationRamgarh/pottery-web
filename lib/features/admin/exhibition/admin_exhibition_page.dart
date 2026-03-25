import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class AdminExhibitionPage extends StatefulWidget {
  const AdminExhibitionPage({super.key});

  @override
  State<AdminExhibitionPage> createState() => _AdminExhibitionPageState();
}

class _AdminExhibitionPageState extends State<AdminExhibitionPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _openTimeCtrl;
  late TextEditingController _closeTimeCtrl;
  late TextEditingController _displayTimeCtrl;
  late TextEditingController _upcomingMsgCtrl;
  late TextEditingController _lastDayMsgCtrl;
  late TextEditingController _thankYouMsgCtrl;

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
    _locCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _openTimeCtrl = TextEditingController();
    _closeTimeCtrl = TextEditingController();
    _displayTimeCtrl = TextEditingController();
    _upcomingMsgCtrl = TextEditingController();
    _lastDayMsgCtrl = TextEditingController();
    _thankYouMsgCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final exh = await FirestoreService.getExhibition();
    if (mounted) {
      setState(() {
        _titleCtrl.text = exh.title;
        _locCtrl.text = exh.location;
        _addressCtrl.text = exh.address;
        _openTimeCtrl.text = exh.openTime;
        _closeTimeCtrl.text = exh.closeTime;
        _displayTimeCtrl.text = exh.displayTime;
        _upcomingMsgCtrl.text = exh.upcomingMessage;
        _lastDayMsgCtrl.text = exh.lastDayMessage;
        _thankYouMsgCtrl.text = exh.thankYouMessage;
        
        _startDate = exh.startDate;
        _endDate = exh.endDate;
        _isActive = exh.isActive;
        _currentImageUrl = exh.imageUrl;
        
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newImageBytes = bytes);
    }
  }

  Future<void> _selectDates(BuildContext context) async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: AppTheme.themeData.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBrown,
              onPrimary: Colors.white,
              surface: AppTheme.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String? imageUrl = _currentImageUrl;
      if (_newImageBytes != null) {
        final urls = await _mediaService.uploadImages(
          docId: 'exhibition',
          pathPrefix: 'exhibition',
          files: [_newImageBytes!],
        );
        imageUrl = urls.first;
      }

      final data = {
        'title': _titleCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'openTime': _openTimeCtrl.text.trim(),
        'closeTime': _closeTimeCtrl.text.trim(),
        'displayTime': _displayTimeCtrl.text.trim(),
        'upcomingMessage': _upcomingMsgCtrl.text.trim(),
        'lastDayMessage': _lastDayMsgCtrl.text.trim(),
        'thankYouMessage': _thankYouMsgCtrl.text.trim(),
        'isActive': _isActive,
        'imageUrl': imageUrl ?? '',
      };

      await FirestoreService.updateConfig('exhibition', data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exhibition updated successfully'), backgroundColor: AppTheme.successGreen),
        );
        setState(() {
          if (_newImageBytes != null) {
            _currentImageUrl = imageUrl;
            _newImageBytes = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locCtrl.dispose();
    _addressCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    _displayTimeCtrl.dispose();
    _upcomingMsgCtrl.dispose();
    _lastDayMsgCtrl.dispose();
    _thankYouMsgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exhibition', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Manage your upcoming or active pottery exhibition', style: AppTheme.bodyMedium),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes', style: AppTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Text('Is Active', style: AppTheme.headingMedium),
                const SizedBox(width: 16),
                Switch(
                  value: _isActive,
                  activeColor: AppTheme.primaryBrown,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildCard(
              title: 'Exhibition Details',
              children: [
                _buildField('Title', _titleCtrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Location', _locCtrl)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDates(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(10),
                            color: AppTheme.background,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate != null && _endDate != null
                                    ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                                    : 'Select Dates',
                                style: AppTheme.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryBrown, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Address', _addressCtrl, maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Open Time', _openTimeCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Close Time', _closeTimeCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Display Time (e.g. 8:00 AM - 6:00 PM)', _displayTimeCtrl)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCard(
                    title: 'Messages',
                    children: [
                      _buildField('Upcoming Message', _upcomingMsgCtrl, maxLines: 2),
                      const SizedBox(height: 16),
                      _buildField('Last Day Message', _lastDayMsgCtrl),
                      const SizedBox(height: 16),
                      _buildField('Thank You Message', _thankYouMsgCtrl),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildCard(
                    title: 'Exhibition Image',
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                            image: (_newImageBytes != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                                ? DecorationImage(
                                    image: _newImageBytes != null 
                                        ? MemoryImage(_newImageBytes!) as ImageProvider
                                        : NetworkImage(_currentImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (_newImageBytes == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.greyPlaceholder),
                                    const SizedBox(height: 12),
                                    Text('Upload Photo', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium.copyWith(color: AppTheme.textDark)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(label: label, hint: 'Enter $label'),
        ),
      ],
    );
  }
}
