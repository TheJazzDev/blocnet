import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/tags_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubmitProjectScreen extends StatefulWidget {
  const SubmitProjectScreen({super.key});

  @override
  State<SubmitProjectScreen> createState() => _SubmitProjectScreenState();
}

class _SubmitProjectScreenState extends State<SubmitProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  final _repository = ProjectProposalsApiRepository();

  String? _selectedPrimaryTagId;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tagsStore = context.read<TagsStore>();
      await tagsStore.fetchOnce();
      if (!mounted) return;

      if (_selectedPrimaryTagId == null && tagsStore.primaryTags.isNotEmpty) {
        setState(() {
          _selectedPrimaryTagId = tagsStore.primaryTags.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final tagsStore = context.watch<TagsStore>();

    if (!auth.canSubmitProject) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Your current role does not allow project submission.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Geist',
            ),
          ),
        ),
      );
    }

    if (tagsStore.isLoading && tagsStore.primaryTags.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal400,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (tagsStore.primaryTags.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Primary tags are not configured yet. Contact admin.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Geist',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_submitError != null && _submitError!.isNotEmpty) ...[
                Text(
                  _submitError!,
                  style: TextStyle(
                    color: AppColors.error500,
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _FieldLabel('Project name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: _fieldDecoration(hintText: 'e.g. Codawoo'),
                validator: (value) {
                  final next = value?.trim() ?? '';
                  if (next.isEmpty) return 'Name is required';
                  if (next.length < 2) return 'Use at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FieldLabel('Symbol (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _symbolController,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: _fieldDecoration(hintText: 'e.g. COD'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('Website URL (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _websiteController,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: _fieldDecoration(hintText: 'https://example.com'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('Primary tag'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPrimaryTagId,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.bgElevated,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Geist',
                ),
                items: tagsStore.primaryTags
                    .map(
                      (tag) => DropdownMenuItem<String>(
                        value: tag.id,
                        child: Text(
                          tag.name,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedPrimaryTagId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a primary tag';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FieldLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 6,
                maxLines: 10,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: _fieldDecoration(
                  hintText: 'Explain what this project is about.',
                ),
                validator: (value) {
                  final next = value?.trim() ?? '';
                  if (next.isEmpty) return 'Description is required';
                  if (next.length < 12) return 'Use at least 12 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FieldLabel('Why should we approve? (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 6,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Geist',
                ),
                decoration: _fieldDecoration(
                  hintText: 'Credibility, risk checks, relevance, etc.',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _isSubmitting
                          ? null
                          : LinearGradient(
                              colors: [AppColors.teal500, AppColors.primary500],
                            ),
                      color: _isSubmitting ? AppColors.bgElevated : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSubmitting
                        ? Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.teal400,
                              ),
                            ),
                          )
                        : Text(
                            'Submit For Approval',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textMuted),
      title: Text(
        'Submit Project',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.textFaint,
        fontSize: 13,
        fontFamily: 'Geist',
      ),
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.teal500),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error500),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final response = await _repository.submitProposal(
        name: _nameController.text.trim(),
        symbol: _symbolController.text.trim().isEmpty
            ? null
            : _symbolController.text.trim(),
        websiteUrl: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        description: _descriptionController.text.trim(),
        primaryTagId: _selectedPrimaryTagId!,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );
      if (response == null) {
        throw Exception('Could not submit project proposal. Please retry.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project submitted for approval')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontFamily: 'Geist',
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
