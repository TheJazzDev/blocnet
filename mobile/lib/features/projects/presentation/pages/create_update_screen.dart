import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_author_scope.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_deadline_field.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_form.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_notice.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_project_picker.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/create_update_empty_state.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
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
        _submitError = "Couldn't load this update. Go back and try again.";
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
      projects: ComposerAuthorScope.projectsFor(
        auth: auth,
        projects: projectsStore.projects,
      ),
    ));

    if (!widget.isEdit && _selectedProjectId == null && options.isNotEmpty) {
      _selectedProjectId = options.first.id;
    }

    if (!auth.canCreateUpdate) {
      return _scaffold(const ComposerNotice(
        icon: Icons.lock_outline_rounded,
        title: "Your role can't post updates",
      ));
    }

    final waiting =
        _loadingOriginal || (projectsStore.isFetching && options.isEmpty);
    if (waiting) return _scaffold(const ComposerLoading());

    if (options.isEmpty) {
      return _scaffold(CreateUpdateEmptyState(
        isHunterRestricted: ComposerAuthorScope.isHunterRestricted(auth),
      ));
    }

    return _scaffold(ComposerForm(
      formKey: _formKey,
      title: _titleController,
      content: _contentController,
      options: options,
      tags: tagsStore.secondaryTags,
      state: ComposerFormState(
        projectId: _selectedProjectId,
        priority: _selectedPriority,
        deadlineAt: _deadlineAt,
        tagIds: _selectedSecondaryTagIds,
        isEdit: widget.isEdit,
        busy: _isSubmitting,
        error: _submitError,
      ),
      callbacks: ComposerFormCallbacks(
        onProject: (value) => setState(() => _selectedProjectId = value),
        onPriority: (value) => setState(() => _selectedPriority = value),
        onPickDeadline: _pickDeadline,
        onClearDeadline: () => setState(() => _deadlineAt = null),
        onToggleTag: (id, selected) => setState(() {
          selected
              ? _selectedSecondaryTagIds.add(id)
              : _selectedSecondaryTagIds.remove(id);
        }),
        onSubmit: _submit,
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
    final toast = AppSnackbar.of(context);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tagIds = _selectedSecondaryTagIds.toList();

    try {
      final original = _original;
      if (widget.isEdit) {
        if (original == null) throw Exception('This update did not load.');
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
          throw Exception('The update was not created. Try again.');
        }
      }

      await Future.wait([
        updatesStore.refreshUpdates(),
        projectsStore.refreshProjects(),
        notificationsStore.refreshNotifications(category: 'all'),
      ]);

      if (!mounted) return;
      toast.success(widget.isEdit ? 'Update saved' : 'Update published');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = composerErrorText(error);
      setState(() => _submitError = message);
      toast.error(widget.isEdit
          ? "Couldn't save: $message"
          : "Couldn't publish: $message");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
