import 'package:flutter/material.dart';

import '../../../core/repositories/support_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/support_message.dart';

class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  final _resolutionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  List<SupportMessage> _requests = [];
  SupportMessage? _selected;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requests = await SupportRepository.getAll();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _isLoading = false;
      if (_selected != null) {
        _selected = requests.firstWhere(
          (item) => item.id == _selected!.id,
          orElse: () => requests.isNotEmpty ? requests.first : _selected!,
        );
      } else if (requests.isNotEmpty) {
        _setSelected(requests.first);
      }
    });
  }

  void _setSelected(SupportMessage message) {
    _selected = message;
    _status = message.status;
    _resolutionController.text = message.resolutionNote;
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null) return;

    setState(() => _isSaving = true);
    try {
      await SupportRepository.updateStatus(
        selected.id,
        _status,
        resolutionNote: _resolutionController.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Support request updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update request: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.terracotta),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildList()),
                  const SizedBox(width: 24),
                  Expanded(flex: 7, child: _buildDetail()),
                ],
              ),
            ),
    );
  }

  Widget _buildList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Support & Returns', style: AppTheme.headingLarge),
          const SizedBox(height: 20),
          if (_requests.isEmpty)
            Text('No support requests yet.', style: AppTheme.bodyLarge)
          else
            ..._requests.map(
              (request) => InkWell(
                onTap: () => setState(() => _setSelected(request)),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selected?.id == request.id
                        ? AppTheme.exhibitionBackground
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selected?.id == request.id
                          ? AppTheme.terracotta
                          : AppTheme.divider,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.subject.isEmpty ? 'Request' : request.subject,
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${request.type} • ${request.status}',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(request.email, style: AppTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    final selected = _selected;
    if (selected == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text('Select a request to review', style: AppTheme.bodyLarge),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected.subject.isEmpty ? 'Support Request' : selected.subject,
            style: AppTheme.headingLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${selected.name} • ${selected.email}',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: AppTheme.inputDecoration(label: 'Status'),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('OPEN')),
              DropdownMenuItem(value: 'in_review', child: Text('IN REVIEW')),
              DropdownMenuItem(value: 'resolved', child: Text('RESOLVED')),
              DropdownMenuItem(value: 'closed', child: Text('CLOSED')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 16),
          Text(selected.message, style: AppTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _resolutionController,
            maxLines: 5,
            decoration: AppTheme.inputDecoration(label: 'Resolution note'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
              ),
              child: Text(_isSaving ? 'SAVING...' : 'SAVE UPDATE'),
            ),
          ),
        ],
      ),
    );
  }
}
