import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_choice_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_deadline_field.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_project_picker.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/create_update_empty_state.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The update composer.
///
/// Opens empty, with [projectId] pre-selected, or — with [updateId] — in
/// edit mode, prefilled and saved as a `PATCH /updates/:id`. Pops `true`
/// after a publish or save so the caller can refresh what it shows.
class CreateUpdateScreen extends StatefulWidget {
  const CreateUpdateScreen({super.key, this.projectId, this.updateId});

  final String? projectId;
  final String? updateId;

  bool get isEdit => updateId != null && updateId!.isNotEmpty;

  @override
  State<CreateUpdateScreen> createState() => _CreateUpdateScreenState();
}

class _CreateUpdateScreenState extends State<CreateUpdateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Priority _selectedPriority = Priority.mid;

  /// When the window this update describes closes. Optional, and null for most
  /// updates: a hunter only sets it when there is a real window to miss.
  DateTime? _deadlineAt;
  String? _selectedProjectId;
  final Set<String> _selectedSecondaryTagIds = <String>{};
  bool _isSubmitting = false;
  String? _submitError;

  /// Edit mode: the update being edited, and whether it is still loading.
  Update? _original;
  bool _loadingOriginal = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    _loadingOriginal = widget.isEdit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prime());
  }

  Future<void> _prime() async {
    final projectsStore = context.read<ProjectsStore>();
    final board = context.read<HunterBoardStore>();
    final updates = context.read<UpdatesStore>();
    await Future.wait([
      projectsStore.fetchProjectsOnce(),
      context.read<TagsStore>().fetchOnce(),
      if (board.board == null) board.loadBoard(),
      if (widget.isEdit) _loadOriginal(updates),
    ]);
  }

  Future<void> _loadOriginal(UpdatesStore updates) async {
    final update = await updates.loadUpdate(widget.updateId!);
    if (!mounted) return;
    setState(() {
      _loadingOriginal = false;
      _original = update;
      if (update == null) {
        _submitError = 'Could not load this update. Please try again.';
        return;
      }
      _titleController.text = update.title;
      _contentController.text = update.content;
      _selectedPriority = update.priority;
      _deadlineAt = update.deadlineAt?.toLocal();
      _selectedProjectId = update.projectId;
      _selectedSecondaryTagIds
        ..clear()
        ..addAll(update.allSecondaryTagIds);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final projectsStore = context.watch<ProjectsStore>();
    final tagsStore = context.watch<TagsStore>();
    final board = context.watch<HunterBoardStore>().board;
    final options = _withSelected(composerProjectOptions(
      boardGems: board?.gems ?? const [],
      projects: _availableProjectsForAuthor(
        auth: auth,
        projects: projectsStore.projects,
      ),
    ));

    if (!widget.isEdit && _selectedProjectId == null && options.isNotEmpty) {
      _selectedProjectId = options.first.id;
    }

    if (!auth.canCreateUpdate) {
      return _scaffold(Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Text(
          'Your current role does not allow creating updates.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.bodySize,
            weight: FontWeight.w400,
          ),
        ),
      ));
    }

    final waiting =
        _loadingOriginal || (projectsStore.isFetching && options.isEmpty);
    if (waiting) {
      return _scaffold(Center(
        child: CircularProgressIndicator(
          color: AppColors.teal400,
          strokeWidth: 2,
        ),
      ));
    }

    if (options.isEmpty) {
      return _scaffold(CreateUpdateEmptyState(
        isHunterRestricted: _isHunterRestricted(auth),
      ));
    }

    return _scaffold(Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_submitError != null && _submitError!.isNotEmpty) ...[
              Text(
                _submitError!,
                style: AppTypography.custom(
                  color: AppColors.error500,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            const ComposerFieldLabel('Project'),
            const SizedBox(height: AppSpace.sm),
            ComposerProjectPicker(
              options: options,
              value: _selectedProjectId,
              enabled: !widget.isEdit,
              onChanged: (value) => setState(() => _selectedProjectId = value),
            ),
            const SizedBox(height: AppSpace.lg),
            const ComposerFieldLabel('Urgency'),
            const SizedBox(height: AppSpace.sm),
            ComposerPriorityPicker(
              value: _selectedPriority,
              onChanged: (value) => setState(() => _selectedPriority = value),
            ),
            const SizedBox(height: AppSpace.lg),
            const ComposerFieldLabel('Closing window (optional)'),
            const SizedBox(height: AppSpace.sm),
            ComposerDeadlineField(
              value: _deadlineAt,
              onPick: _pickDeadline,
              onClear: () => setState(() => _deadlineAt = null),
            ),
            const SizedBox(height: AppSpace.lg),
            const ComposerFieldLabel('Secondary tags'),
            const SizedBox(height: AppSpace.sm),
            ComposerTagPicker(
              tags: tagsStore.secondaryTags,
              selected: _selectedSecondaryTagIds,
              onToggle: (id, selected) => setState(() {
                selected
                    ? _selectedSecondaryTagIds.add(id)
                    : _selectedSecondaryTagIds.remove(id);
              }),
            ),
            const SizedBox(height: AppSpace.lg),
            const ComposerFieldLabel('Title'),
            const SizedBox(height: AppSpace.sm),
            TextFormField(
              key: const ValueKey('composer-title'),
              controller: _titleController,
              style: composerValueStyle(),
              decoration: composerFieldDecoration(hintText: 'Update title'),
              validator: (value) {
                final next = value?.trim() ?? '';
                if (next.isEmpty) return 'Title is required';
                if (next.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpace.lg),
            const ComposerFieldLabel('Content'),
            const SizedBox(height: AppSpace.sm),
            TextFormField(
              key: const ValueKey('composer-content'),
              controller: _contentController,
              minLines: 7,
              maxLines: 12,
              style: composerValueStyle(),
              decoration: composerFieldDecoration(
                hintText: 'Write your update (markdown supported)',
              ),
              validator: (value) {
                final next = value?.trim() ?? '';
                if (next.isEmpty) return 'Content is required';
                if (next.length < 16) return 'Use at least 16 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpace.xl),
            ComposerSubmitButton(
              label: widget.isEdit ? 'Save changes' : 'Publish Update',
              busy: _isSubmitting,
              onTap: _submit,
            ),
          ],
        ),
      ),
    ));
  }

  Widget _scaffold(Widget body) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: widget.isEdit ? 'Edit update' : 'Create Update',
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
      ),
      body: body,
    );
  }

  /// Keeps a pre-selected or edited gem pickable even before the lists that
  /// would name it have loaded.
  List<ComposerProjectOption> _withSelected(
      List<ComposerProjectOption> options) {
    final id = _selectedProjectId;
    if (id == null || options.any((o) => o.id == id)) return options;
    return [
      ComposerProjectOption(
        id: id,
        name: _original?.project?.name ?? 'This gem',
      ),
      ...options,
    ];
  }

  Future<void> _pickDeadline() async {
    final picked = await pickComposerDeadline(context, _deadlineAt);
    if (picked == null || !mounted) return;
    setState(() => _deadlineAt = picked);
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    final projectId = _selectedProjectId;
    if (projectId == null || projectId.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final updatesStore = context.read<UpdatesStore>();
    final projectsStore = context.read<ProjectsStore>();
    final notificationsStore = context.read<NotificationsStore>();
    final messenger = ScaffoldMessenger.of(context);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tagIds = _selectedSecondaryTagIds.toList();

    try {
      final original = _original;
      if (widget.isEdit) {
        if (original == null) throw Exception('Update not loaded.');
        await updatesStore.updateUpdate(original.withEdits(
          title: title,
          content: content,
          priority: _selectedPriority,
          deadlineAt: _deadlineAt,
          secondaryTagIds: tagIds,
        ));
      } else {
        final created = await updatesStore.createUpdate(
          projectId: projectId,
          title: title,
          content: content,
          priority: _selectedPriority,
          secondaryTagIds: tagIds,
          deadlineAt: _deadlineAt,
        );
        if (created == null) {
          throw Exception('Could not create update. Please try again.');
        }
      }

      await Future.wait([
        updatesStore.refreshUpdates(),
        projectsStore.refreshProjects(),
        notificationsStore.refreshNotifications(category: 'all'),
      ]);

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isEdit ? 'Update saved' : 'Update published'),
      ));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitError = error.toString());
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isEdit
            ? 'Failed to save: $error'
            : 'Failed to publish: $error'),
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<Project> _availableProjectsForAuthor({
    required AuthStore auth,
    required List<Project> projects,
  }) {
    if (!_isHunterRestricted(auth)) return projects;

    final userId = auth.userId?.trim() ?? '';
    final username =
        _normalizeIdentity(auth.username ?? auth.displayName ?? '');

    return projects.where((project) {
      if (userId.isNotEmpty &&
          (project.adminId == userId || project.admin?.id == userId)) {
        return true;
      }
      final projectUsername = _normalizeIdentity(
          project.admin?.username ?? project.admin?.name ?? '');
      return username.isNotEmpty && projectUsername == username;
    }).toList(growable: false);
  }

  bool _isHunterRestricted(AuthStore auth) {
    return auth.isInHunterSpace ||
        (auth.isHunter && !auth.isOwner && !auth.isAdmin);
  }

  String _normalizeIdentity(String value) {
    return value.replaceAll('@', '').trim().toLowerCase();
  }
}
