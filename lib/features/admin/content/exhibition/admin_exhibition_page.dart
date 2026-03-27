import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../models/app_config.dart';
import 'package:image_picker/image_picker.dart';
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
  late TextEditingController _locationCtrl;
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
    _locationCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _openTimeCtrl = TextEditingController();
    _closeTimeCtrl = TextEditingController();
    _displayTimeCtrl = TextEditingController();
    _upcomingMsgCtrl = TextEditingController();
    _lastDayMsgCtrl = TextEditingController();
    _thankYouMsgCtrl = TextEditingController();
    _loadExhibition();
  }

  Future<void> _loadExhibition() async {
    try {
      final data = await FirestoreService.getExhibition();
      if (mounted) {
        setState(() {
          _titleCtrl.text = data.title;
          _locationCtrl.text = data.location;
          _addressCtrl.text = data.address;
          _startDate = data.startDate;
          _endDate = data.endDate;
          _openTimeCtrl.text = data.openTime;
          _closeTimeCtrl.text = data.closeTime;
          _displayTimeCtrl.text = data.displayTime;
          _upcomingMsgCtrl.text = data.upcomingMessage;
          _lastDayMsgCtrl.text = data.lastDayMessage;
          _thankYouMsgCtrl.text = data.thankYouMessage;
          _isActive = data.isActive;
          _currentImageUrl = data.imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading exhibition: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newImageBytes = bytes);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryBrown),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveExhibition() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.errorRed));
      return;
    }

    setState(() => _isSaving = true);
    try {
      String imageUrl = _currentImageUrl ?? '';

      if (_newImageBytes != null) {
        final urls = await _mediaService.uploadImages(docId: 'exhibitions', pathPrefix: 'branding', files: [_newImageBytes!]);
        imageUrl = urls.first;
      }

      final exhibitionData = {
        'title': _titleCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'openTime': _openTimeCtrl.text.trim(),
        'closeTime': _closeTimeCtrl.text.trim(),
        'displayTime': _displayTimeCtrl.text.trim(),
        'imageUrl': imageUrl,
        'isActive': _isActive,
        'thankYouMessage': _thankYouMsgCtrl.text.trim(),
        'lastDayMessage': _lastDayMsgCtrl.text.trim(),
        'upcomingMessage': _upcomingMsgCtrl.text.trim(),
      };

      await FirestoreService.updateConfig('exhibition', exhibitionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exhibition updated successfully!'), backgroundColor: AppTheme.successGreen),
        );
        setState(() {
          _currentImageUrl = imageUrl;
          _newImageBytes = null;
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
    _locationCtrl.dispose();
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
            // ── HEADER ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exhibition Management', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Manage the live or upcoming exhibition details', style: AppTheme.bodyMedium),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveExhibition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Exhibition', style: AppTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text('Status Toggle (Is Active)', style: AppTheme.headingMedium),
                    subtitle: Text('Enable this to show the exhibition across the app', style: AppTheme.bodySmall),
                    activeColor: AppTheme.successGreen,
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSection('Core Info', [
                    _buildField('Title', _titleCtrl),
                    const SizedBox(height: 16),
                    _buildField('Location (Short)', _locationCtrl),
                    const SizedBox(height: 16),
                    _buildField('Full Address', _addressCtrl, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildField('Display Time (e.g. "10am - 6pm")', _displayTimeCtrl),
                  ]),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildSection('Dates & Setup', [
                    Row(
                      children: [
                        Expanded(child: _buildDateBtn('Start Date', _startDate, () => _selectDate(context, true))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateBtn('End Date', _endDate, () => _selectDate(context, false))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('Open Time', _openTimeCtrl)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField('Close Time', _closeTimeCtrl)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildImageCard('Exhibition Image', _newImageBytes, _currentImageUrl, _pickImage),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSection('Dynamic Messages', [
              _buildField('Upcoming Message (e.g. "Coming Soon to Ramgarh")', _upcomingMsgCtrl),
              const SizedBox(height: 16),
              _buildField('Last Day Message', _lastDayMsgCtrl),
              const SizedBox(height: 16),
              _buildField('Thank You Message (Post-exhibition)', _thankYouMsgCtrl),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
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

  Widget _buildDateBtn(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? "${date.day}/${date.month}/${date.year}" : 'Select Date',
                  style: AppTheme.bodyLarge.copyWith(color: date != null ? AppTheme.textDark : AppTheme.greyPlaceholder),
                ),
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(String title, Uint8List? localBytes, String? networkUrl, VoidCallback onPick) {
    bool hasImage = localBytes != null || (networkUrl != null && networkUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
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
              image: hasImage ? DecorationImage(
                image: localBytes != null ? MemoryImage(localBytes) as ImageProvider : NetworkImage(networkUrl!),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: hasImage ? null : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.greyPlaceholder),
                const SizedBox(height: 12),
                Text('Upload Image', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
