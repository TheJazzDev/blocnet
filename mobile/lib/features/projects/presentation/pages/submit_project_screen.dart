import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/tags_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
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
        appBar: AppBar(
          title: const Text('Submit Project'),
          centerTitle: false,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: StyledBodyText500(
            'Your current role does not allow project submission.',
          ),
        ),
      );
    }

    if (tagsStore.isLoading && tagsStore.primaryTags.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Submit Project'),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (tagsStore.primaryTags.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Submit Project'),
          centerTitle: false,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: StyledBodyText500(
            'Primary tags are not configured yet. Contact admin.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Project'),
        centerTitle: false,
      ),
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
              const StyledBodyText500('Project name', size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
                decoration: _fieldDecoration(hintText: 'e.g. Codawoo'),
                validator: (value) {
                  final next = value?.trim() ?? '';
                  if (next.isEmpty) return 'Name is required';
                  if (next.length < 2) return 'Use at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const StyledBodyText500('Symbol (optional)', size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _symbolController,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
                decoration: _fieldDecoration(hintText: 'e.g. COD'),
              ),
              const SizedBox(height: 14),
              const StyledBodyText500('Website URL (optional)', size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _websiteController,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
                decoration: _fieldDecoration(hintText: 'https://example.com'),
              ),
              const SizedBox(height: 14),
              const StyledBodyText500('Primary tag', size: 12),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPrimaryTagId,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.darkGrey100,
                items: tagsStore.primaryTags
                    .map(
                      (tag) => DropdownMenuItem<String>(
                        value: tag.id,
                        child: StyledBodyText600(tag.name, size: 13),
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
              const StyledBodyText500('Description', size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 6,
                maxLines: 10,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
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
              const StyledBodyText500('Why should we approve? (optional)',
                  size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 6,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
                decoration: _fieldDecoration(
                  hintText: 'Credibility, risk checks, relevance, etc.',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit For Approval',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
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

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.darkGrey500,
        fontSize: 13,
        fontFamily: 'Geist',
      ),
      filled: true,
      fillColor: AppColors.darkGrey100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkGrey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkGrey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary500),
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
