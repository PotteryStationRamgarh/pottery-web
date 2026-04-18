import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/repositories/about_us_repository.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/about_us_model.dart';
import '../branding/widgets/field_input.dart';
import '../branding/widgets/image_upload_card.dart';
import '../branding/widgets/section_card.dart';

class AdminAboutUsPage extends StatefulWidget {
  const AdminAboutUsPage({super.key});

  @override
  State<AdminAboutUsPage> createState() => _AdminAboutUsPageState();
}

class _AdminAboutUsPageState extends State<AdminAboutUsPage> {
  final _imagePicker = ImagePicker();
  final _mediaService = MediaService();

  // ── Text controllers ─────────────────────────────────────────
  final _introCtrl = TextEditingController();
  final _artisanName1Ctrl = TextEditingController();
  final _artisanRole1Ctrl = TextEditingController();
  final _artisanAbout1Ctrl = TextEditingController();
  final _artisanName2Ctrl = TextEditingController();
  final _artisanRole2Ctrl = TextEditingController();
  final _artisanAbout2Ctrl = TextEditingController();
  final _sustainabilityTitleCtrl = TextEditingController();
  final _sustainabilityBodyCtrl = TextEditingController();
  final List<TextEditingController> _procHeadCtrls =
      List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _procDescCtrls =
      List.generate(3, (_) => TextEditingController());

  // ── Image state ──────────────────────────────────────────────
  Uint8List? _introImageBytes;
  Uint8List? _artisan1Bytes;
  Uint8List? _artisan2Bytes;
  final List<Uint8List?> _procImageBytes = List.filled(3, null);

  // ── Pending deletes (R2 URLs to delete on save) ──────────────
  String? _pendingDeleteIntroImage;
  String? _pendingDeleteArtisan1;
  String? _pendingDeleteArtisan2;
  final List<String?> _pendingDeleteProcImages = List.filled(3, null);

  // ── Page state ───────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  AboutUsModel _current = AboutUsModel.empty();

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _artisanName1Ctrl.dispose();
    _artisanRole1Ctrl.dispose();
    _artisanAbout1Ctrl.dispose();
    _artisanName2Ctrl.dispose();
    _artisanRole2Ctrl.dispose();
    _artisanAbout2Ctrl.dispose();
    _sustainabilityTitleCtrl.dispose();
    _sustainabilityBodyCtrl.dispose();
    for (final c in _procHeadCtrls) {
      c.dispose();
    }
    for (final c in _procDescCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final data = await AboutUsRepository.getAboutUs();
      _current = data;
      _syncControllers(data);
    } catch (e) {
      _showMessage('Failed to load About Us config: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncControllers(AboutUsModel d) {
    _introCtrl.text = d.intro;
    _artisanName1Ctrl.text = d.artisanName1;
    _artisanRole1Ctrl.text = d.artisanRole1;
    _artisanAbout1Ctrl.text = d.artisanAbout1;
    _artisanName2Ctrl.text = d.artisanName2;
    _artisanRole2Ctrl.text = d.artisanRole2;
    _artisanAbout2Ctrl.text = d.artisanAbout2;
    _sustainabilityTitleCtrl.text = d.sustainabilityTitle;
    _sustainabilityBodyCtrl.text = d.sustainabilityBody;
    for (int i = 0; i < 3; i++) {
      _procHeadCtrls[i].text = i < d.procedureHead.length ? d.procedureHead[i] : '';
      _procDescCtrls[i].text = i < d.procedureDesc.length ? d.procedureDesc[i] : '';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // IMAGE PICKERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickIntroImage() async {
    final img = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    // Mark old URL for deletion on save
    if (_current.introImage.isNotEmpty) {
      _pendingDeleteIntroImage = _current.introImage;
    }
    setState(() => _introImageBytes = bytes);
  }

  void _clearIntroImage() {
    _pendingDeleteIntroImage = _current.introImage;
    setState(() {
      _introImageBytes = null;
      _current = AboutUsModel(
        intro: _current.intro,
        introImage: '', // cleared
        artisanName1: _current.artisanName1,
        artisanRole1: _current.artisanRole1,
        artisanAbout1: _current.artisanAbout1,
        artisanPic1: _current.artisanPic1,
        artisanName2: _current.artisanName2,
        artisanRole2: _current.artisanRole2,
        artisanAbout2: _current.artisanAbout2,
        artisanPic2: _current.artisanPic2,
        procedureHead: _current.procedureHead,
        procedureDesc: _current.procedureDesc,
        procedureImage: _current.procedureImage,
        sustainabilityTitle: _current.sustainabilityTitle,
        sustainabilityBody: _current.sustainabilityBody,
      );
    });
  }

  Future<void> _pickArtisanImage(int artisanIndex) async {
    final img = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (artisanIndex == 1) {
        if (_current.artisanPic1.isNotEmpty) {
          _pendingDeleteArtisan1 = _current.artisanPic1;
        }
        _artisan1Bytes = bytes;
      } else {
        if (_current.artisanPic2.isNotEmpty) {
          _pendingDeleteArtisan2 = _current.artisanPic2;
        }
        _artisan2Bytes = bytes;
      }
    });
  }

  void _clearArtisanImage(int artisanIndex) {
    setState(() {
      if (artisanIndex == 1) {
        _pendingDeleteArtisan1 = _current.artisanPic1;
        _artisan1Bytes = null;
        _current = _current._copyWith(artisanPic1: '');
      } else {
        _pendingDeleteArtisan2 = _current.artisanPic2;
        _artisan2Bytes = null;
        _current = _current._copyWith(artisanPic2: '');
      }
    });
  }

  Future<void> _pickProcedureImage(int index) async {
    final img = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      final existingUrl =
          index < _current.procedureImage.length ? _current.procedureImage[index] : '';
      if (existingUrl.isNotEmpty) _pendingDeleteProcImages[index] = existingUrl;
      _procImageBytes[index] = bytes;
    });
  }

  void _clearProcedureImage(int index) {
    setState(() {
      final existingUrl =
          index < _current.procedureImage.length ? _current.procedureImage[index] : '';
      if (existingUrl.isNotEmpty) _pendingDeleteProcImages[index] = existingUrl;
      _procImageBytes[index] = null;
      final updated = List<String>.from(_current.procedureImage);
      while (updated.length <= index) {
        updated.add('');
      }
      updated[index] = '';
      _current = _current._copyWith(procedureImage: updated);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      // ── 1. Delete pending R2 objects ──────────────────────────
      final toDelete = <String>[];
      if (_pendingDeleteIntroImage != null &&
          _pendingDeleteIntroImage!.isNotEmpty) {
        toDelete.add(_pendingDeleteIntroImage!);
      }
      if (_pendingDeleteArtisan1 != null && _pendingDeleteArtisan1!.isNotEmpty) {
        toDelete.add(_pendingDeleteArtisan1!);
      }
      if (_pendingDeleteArtisan2 != null && _pendingDeleteArtisan2!.isNotEmpty) {
        toDelete.add(_pendingDeleteArtisan2!);
      }
      for (final url in _pendingDeleteProcImages) {
        if (url != null && url.isNotEmpty) toDelete.add(url);
      }
      if (toDelete.isNotEmpty) {
        _mediaService.uploadStatus.value = 'Cleaning up old images…';
        await _mediaService.deletePublicUrls(toDelete);
      }

      // ── 2. Upload new intro image ─────────────────────────────
      var introImageUrl = _current.introImage;
      if (_introImageBytes != null) {
        _mediaService.uploadStatus.value = 'Uploading hero image…';
        final urls = await _mediaService.uploadImages(
          docId: 'about_us_intro',
          pathPrefix: 'about_us',
          files: [_introImageBytes!],
        );
        if (urls.isNotEmpty) introImageUrl = urls.first;
      }

      // ── 3. Upload artisan photos ──────────────────────────────
      var artisan1Url = _current.artisanPic1;
      if (_artisan1Bytes != null) {
        _mediaService.uploadStatus.value = 'Uploading artisan 1 photo…';
        final urls = await _mediaService.uploadImages(
          docId: 'about_us_artisan_1',
          pathPrefix: 'about_us',
          files: [_artisan1Bytes!],
        );
        if (urls.isNotEmpty) artisan1Url = urls.first;
      }

      var artisan2Url = _current.artisanPic2;
      if (_artisan2Bytes != null) {
        _mediaService.uploadStatus.value = 'Uploading artisan 2 photo…';
        final urls = await _mediaService.uploadImages(
          docId: 'about_us_artisan_2',
          pathPrefix: 'about_us',
          files: [_artisan2Bytes!],
        );
        if (urls.isNotEmpty) artisan2Url = urls.first;
      }

      // ── 4. Upload procedure images ────────────────────────────
      final procUrls = List<String>.from(
        List.generate(3, (i) {
          return i < _current.procedureImage.length
              ? _current.procedureImage[i]
              : '';
        }),
      );
      for (int i = 0; i < 3; i++) {
        final bytes = _procImageBytes[i];
        if (bytes == null) continue;
        _mediaService.uploadStatus.value = 'Uploading material image ${i + 1}…';
        final urls = await _mediaService.uploadImages(
          docId: 'about_us_procedure_${i + 1}',
          pathPrefix: 'about_us',
          files: [bytes],
        );
        if (urls.isNotEmpty) procUrls[i] = urls.first;
      }

      // ── 5. Save to Firestore ──────────────────────────────────
      _mediaService.uploadStatus.value = 'Saving to Firestore…';
      final next = AboutUsModel(
        intro: _introCtrl.text.trim(),
        introImage: introImageUrl,
        artisanName1: _artisanName1Ctrl.text.trim(),
        artisanRole1: _artisanRole1Ctrl.text.trim(),
        artisanAbout1: _artisanAbout1Ctrl.text.trim(),
        artisanPic1: artisan1Url,
        artisanName2: _artisanName2Ctrl.text.trim(),
        artisanRole2: _artisanRole2Ctrl.text.trim(),
        artisanAbout2: _artisanAbout2Ctrl.text.trim(),
        artisanPic2: artisan2Url,
        procedureHead: _procHeadCtrls.map((c) => c.text.trim()).toList(),
        procedureDesc: _procDescCtrls.map((c) => c.text.trim()).toList(),
        procedureImage: procUrls,
        sustainabilityTitle: _sustainabilityTitleCtrl.text.trim(),
        sustainabilityBody: _sustainabilityBodyCtrl.text.trim(),
      );
      await AboutUsRepository.updateAboutUs(next);

      // ── 6. Reset state ────────────────────────────────────────
      _current = next;
      _introImageBytes = null;
      _artisan1Bytes = null;
      _artisan2Bytes = null;
      for (int i = 0; i < 3; i++) {
        _procImageBytes[i] = null;
        _pendingDeleteProcImages[i] = null;
      }
      _pendingDeleteIntroImage = null;
      _pendingDeleteArtisan1 = null;
      _pendingDeleteArtisan2 = null;

      _showMessage('About Us content saved ✓');
      if (mounted) setState(() {});
    } catch (e) {
      _showMessage('Save failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    } finally {
      _mediaService.uploadStatus.value = '';
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        content: Text(msg),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBrown),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // ── Section: Hero ─────────────────────────────────
                SectionCard(
                  title: 'Hero Section',
                  children: [
                    ImageUploadCard(
                      title: 'Hero Image',
                      subtitle:
                          'Displayed on the right side of the About Us hero. '
                          'Recommended: 900×700 px.',
                      localBytes: _introImageBytes,
                      networkUrl: _current.introImage,
                      isCircular: false,
                      onPick: _pickIntroImage,
                    ),
                    if (_current.introImage.isNotEmpty || _introImageBytes != null) ...[
                      const SizedBox(height: 8),
                      _DeleteImageButton(
                        label: 'Remove hero image',
                        onDelete: _clearIntroImage,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FieldInput(
                      label: 'Intro Paragraph',
                      controller: _introCtrl,
                      maxLines: 5,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Section: Artisans ─────────────────────────────
                SectionCard(
                  title: 'Artisans',
                  children: [
                    _buildArtisanEditor(index: 1),
                    const Divider(height: 40),
                    _buildArtisanEditor(index: 2),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Section: Materials ────────────────────────────
                SectionCard(
                  title: 'Materials (Procedure Cards)',
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: i == 2 ? 0 : 24),
                      child: _buildProcedureEditor(i),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // ── Section: Sustainability ───────────────────────
                SectionCard(
                  title: 'Sustainability Banner',
                  children: [
                    FieldInput(
                      label: 'Title',
                      controller: _sustainabilityTitleCtrl,
                    ),
                    const SizedBox(height: 16),
                    FieldInput(
                      label: 'Body',
                      controller: _sustainabilityBodyCtrl,
                      maxLines: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Saving overlay ────────────────────────────────────
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.primaryBrown,
                        ),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<String>(
                          valueListenable: _mediaService.uploadStatus,
                          builder: (_, status, __) => Text(
                            status.isNotEmpty ? status : 'Saving…',
                            style: AppTheme.bodyLarge
                                .copyWith(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About Us', style: AppTheme.headingLarge),
            const SizedBox(height: 4),
            Text(
              'Manage the About page content, artisan profiles, and imagery.',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      FilledButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: const Text('Save Changes'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBrown,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    ],
  );

  Widget _buildArtisanEditor({required int index}) {
    final name = index == 1 ? _artisanName1Ctrl : _artisanName2Ctrl;
    final role = index == 1 ? _artisanRole1Ctrl : _artisanRole2Ctrl;
    final about = index == 1 ? _artisanAbout1Ctrl : _artisanAbout2Ctrl;
    final bytes = index == 1 ? _artisan1Bytes : _artisan2Bytes;
    final currentUrl =
        index == 1 ? _current.artisanPic1 : _current.artisanPic2;
    final hasImage = currentUrl.isNotEmpty || bytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artisan $index',
          style: GoogleFonts.jost(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBrown,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ImageUploadCard(
          title: 'Photo',
          subtitle: 'Portrait photo of the artisan. Square or 3:4 ratio.',
          localBytes: bytes,
          networkUrl: currentUrl,
          isCircular: false,
          onPick: () => _pickArtisanImage(index),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          _DeleteImageButton(
            label: 'Remove artisan $index photo',
            onDelete: () => _clearArtisanImage(index),
          ),
        ],
        const SizedBox(height: 16),
        FieldInput(label: 'Name', controller: name),
        const SizedBox(height: 12),
        FieldInput(
          label: 'Role / Title (e.g. FOUNDING MASTER ARTISAN)',
          controller: role,
        ),
        const SizedBox(height: 12),
        FieldInput(
          label: 'Bio / About',
          controller: about,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildProcedureEditor(int index) {
    final bytes = _procImageBytes[index];
    final currentUrl = index < _current.procedureImage.length
        ? _current.procedureImage[index]
        : '';
    final hasImage = currentUrl.isNotEmpty || bytes != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Material Card ${index + 1}',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ImageUploadCard(
            title: 'Icon / Image',
            subtitle: 'Small icon or image shown at the top of the card.',
            localBytes: bytes,
            networkUrl: currentUrl,
            isCircular: false,
            onPick: () => _pickProcedureImage(index),
          ),
          if (hasImage) ...[
            const SizedBox(height: 8),
            _DeleteImageButton(
              label: 'Remove material image',
              onDelete: () => _clearProcedureImage(index),
            ),
          ],
          const SizedBox(height: 16),
          FieldInput(
            label: 'Heading (e.g. The Clay)',
            controller: _procHeadCtrls[index],
          ),
          const SizedBox(height: 12),
          FieldInput(
            label: 'Description',
            controller: _procDescCtrls[index],
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EXTENSION — quick copyWith for AboutUsModel
// ─────────────────────────────────────────────────────────────────

extension _AboutUsModelX on AboutUsModel {
  AboutUsModel _copyWith({
    String? intro,
    String? introImage,
    String? artisanName1,
    String? artisanRole1,
    String? artisanAbout1,
    String? artisanPic1,
    String? artisanName2,
    String? artisanRole2,
    String? artisanAbout2,
    String? artisanPic2,
    List<String>? procedureHead,
    List<String>? procedureDesc,
    List<String>? procedureImage,
    String? sustainabilityTitle,
    String? sustainabilityBody,
  }) =>
      AboutUsModel(
        intro: intro ?? this.intro,
        introImage: introImage ?? this.introImage,
        artisanName1: artisanName1 ?? this.artisanName1,
        artisanRole1: artisanRole1 ?? this.artisanRole1,
        artisanAbout1: artisanAbout1 ?? this.artisanAbout1,
        artisanPic1: artisanPic1 ?? this.artisanPic1,
        artisanName2: artisanName2 ?? this.artisanName2,
        artisanRole2: artisanRole2 ?? this.artisanRole2,
        artisanAbout2: artisanAbout2 ?? this.artisanAbout2,
        artisanPic2: artisanPic2 ?? this.artisanPic2,
        procedureHead: procedureHead ?? this.procedureHead,
        procedureDesc: procedureDesc ?? this.procedureDesc,
        procedureImage: procedureImage ?? this.procedureImage,
        sustainabilityTitle: sustainabilityTitle ?? this.sustainabilityTitle,
        sustainabilityBody: sustainabilityBody ?? this.sustainabilityBody,
      );
}

// ─────────────────────────────────────────────────────────────────
// DELETE IMAGE BUTTON
// ─────────────────────────────────────────────────────────────────

class _DeleteImageButton extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  const _DeleteImageButton({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline,
            size: 14,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 12,
              color: Colors.red.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
