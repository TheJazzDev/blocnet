import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/submit/submit_gem_form.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_notice.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sends a gem proposal; returns the created proposal, or null.
typedef ProposalSubmit = Future<Map<String, dynamic>?> Function({
  required String name,
  String? symbol,
  String? websiteUrl,
  required String description,
  required String primaryTagId,
  String? reason,
});

/// Submit New Gem: a hunter proposes a gem for approval.
class SubmitProjectScreen extends StatefulWidget {
  const SubmitProjectScreen({super.key, this.submit});

  /// Injectable for tests; `POST /project-proposals` otherwise.
  final ProposalSubmit? submit;

  @override
  State<SubmitProjectScreen> createState() => _SubmitProjectScreenState();
}

class _SubmitProjectScreenState extends State<SubmitProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = SubmitGemControllers();

  String? _chainId;
  bool _isSubmitting = false;
  String? _submitError;

  /// True until the first tag read has returned, so an empty list is not
  /// mistaken for "no tags configured" on the first frame.
  bool _loadingTags = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTags());
  }

  Future<void> _loadTags({bool force = false}) async {
    final tags = context.read<TagsStore>();
    if (mounted) setState(() => _loadingTags = true);
    await (force ? tags.refresh() : tags.fetchOnce());
    if (!mounted) return;
    setState(() {
      _loadingTags = false;
      if (_chainId == null && tags.primaryTags.isNotEmpty) {
        _chainId = tags.primaryTags.first.id;
      }
    });
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final tags = context.watch<TagsStore>();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Submit New Gem',
        showSearch: false,
        showSpaceSwitcher: false,
      ),
      body: _body(auth, tags),
    );
  }

  Widget _body(AuthStore auth, TagsStore tags) {
    if (!auth.canSubmitProject) {
      return const ComposerNotice(
        icon: Icons.lock_outline_rounded,
        title: "Your role can't submit gems",
        message: 'Hunters and admins can propose gems.',
      );
    }
    if (tags.primaryTags.isEmpty) {
      if (_loadingTags || tags.isLoading) return const ComposerLoading();
      if (tags.lastError != null) {
        return ComposerNotice(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load chains",
          message: 'Check your connection.',
          actionLabel: 'Try again',
          onAction: () => _loadTags(force: true),
        );
      }
      return const ComposerNotice(
        icon: Icons.label_off_outlined,
        title: 'No chains set up yet',
        message: 'An admin adds them from the console.',
      );
    }
    return SubmitGemForm(
      formKey: _formKey,
      fields: _fields,
      chains: tags.primaryTags,
      chainId: _chainId,
      onChain: (id) => setState(() => _chainId = id),
      busy: _isSubmitting,
      error: _submitError,
      onSubmit: _submit,
    );
  }

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    final chainId = _chainId;
    if (form == null || !form.validate() || chainId == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final send =
        widget.submit ?? ProjectProposalsApiRepository().submitProposal;

    try {
      final response = await send(
        name: _fields.name.text.trim(),
        symbol: _optional(_fields.symbol),
        websiteUrl: _optional(_fields.website),
        description: _fields.description.text.trim(),
        primaryTagId: chainId,
        reason: _optional(_fields.reason),
      );
      if (response == null) {
        throw Exception('The proposal was not sent. Try again.');
      }
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Gem submitted for approval')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = composerErrorText(error);
      setState(() => _submitError = message);
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't submit: $message")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
