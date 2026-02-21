import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/tags_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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
            style: AppTypography.custom(color: AppColors.textMuted,
              size: 13,
              weight: FontWeight.w400,),
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
            style: AppTypography.custom(color: AppColors.textMuted,
              size: 13,
              weight: FontWeight.w400,),
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
                  style: AppTypography.custom(color: AppColors.error500,
                    size: 12,
                    weight: FontWeight.w400,),
                ),
                const SizedBox(height: 10),
              ],
              _FieldLabel('Gem name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
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
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
                decoration: _fieldDecoration(hintText: 'e.g. COD'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('Website URL (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _websiteController,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
                decoration: _fieldDecoration(hintText: 'https://example.com'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('Primary tag'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPrimaryTagId,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.bgElevated,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w400,),
                items: tagsStore.primaryTags
                    .map(
                      (tag) => DropdownMenuItem<String>(
                        value: tag.id,
                        child: Text(
                          tag.name,
                          style: AppTypography.custom(
                            color: AppColors.textSecondary,
                            size: 13,
                            weight: FontWeight.w500,
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
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
                decoration: _fieldDecoration(
                  hintText: 'Explain what this gem is about.',
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
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
                decoration: _fieldDecoration(
                  hintText: 'Credibility, risk checks, relevance, etc.',
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _isSubmitting ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: _isSubmitting
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.teal400,
                              AppColors.primary500,
                            ],
                          ),
                    color: _isSubmitting ? AppColors.bgElevated : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSubmitting
                          ? AppColors.borderSubtle
                          : AppColors.teal400.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: _isSubmitting
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.teal400.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: _isSubmitting
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.teal400,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Submit For Approval',
                              style: AppTypography.custom(
                                color: Colors.black,
                                size: 15,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
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
        'Submit New Gem',
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: 16,
          weight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.custom(
        color: AppColors.textFaint,
        size: 13,
        weight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.teal400,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.error500,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.error500,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        throw Exception('Could not submit gem proposal. Please retry.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gem submitted for approval')),
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
      style: AppTypography.custom(
        color: AppColors.textMuted,
        size: 12,
        weight: FontWeight.w500,
      ),
    );
  }
}
