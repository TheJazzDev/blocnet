import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/create_update_empty_state.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/services/projects/tags_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class CreateUpdateScreen extends StatefulWidget {
  const CreateUpdateScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectsStore = context.read<ProjectsStore>();
      final tagsStore = context.read<TagsStore>();
      await Future.wait([
        projectsStore.fetchProjectsOnce(),
        tagsStore.fetchOnce(),
      ]);
      if (!mounted) return;

      final availableProjects = _availableProjectsForAuthor(
        auth: context.read<AuthStore>(),
        projects: projectsStore.projects,
      );

      if (_selectedProjectId == null && availableProjects.isNotEmpty) {
        setState(() {
          _selectedProjectId = availableProjects.first.id;
        });
      }
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
    final availableProjects = _availableProjectsForAuthor(
      auth: auth,
      projects: projectsStore.projects,
    );

    if (_selectedProjectId != null &&
        availableProjects
            .every((project) => project.id != _selectedProjectId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedProjectId =
              availableProjects.isNotEmpty ? availableProjects.first.id : null;
        });
      });
    }

    if (!auth.canCreateUpdate) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Text(
            'Your current role does not allow creating updates.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    if (projectsStore.isFetching && availableProjects.isEmpty) {
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

    if (availableProjects.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _buildAppBar(),
        body: CreateUpdateEmptyState(
          isHunterRestricted: _isHunterRestricted(auth),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(),
      body: Form(
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
              _FieldLabel('Project'),
              const SizedBox(height: AppSpace.sm),
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.bgElevated,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
                items: availableProjects
                    .map(
                      (project) => DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(
                          project.name,
                          style: AppTypography.custom(
                            color: AppColors.textSecondary,
                            size: AppText.labelSize,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedProjectId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.lg),
              _FieldLabel('Urgency'),
              const SizedBox(height: AppSpace.sm),
              DropdownButtonFormField<Priority>(
                value: _selectedPriority,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.bgElevated,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
                items: Priority.getAll()
                    .map(
                      (priority) => DropdownMenuItem<Priority>(
                        value: priority,
                        child: Text(
                          '${priority.label} Urgency',
                          style: AppTypography.custom(
                            color: AppColors.textSecondary,
                            size: AppText.labelSize,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedPriority = value);
                },
              ),
              const SizedBox(height: AppSpace.lg),
              _FieldLabel('Closing window (optional)'),
              const SizedBox(height: AppSpace.sm),
              _DeadlineField(
                value: _deadlineAt,
                onPick: _pickDeadline,
                onClear: () => setState(() => _deadlineAt = null),
              ),
              const SizedBox(height: AppSpace.lg),
              _FieldLabel('Secondary tags'),
              const SizedBox(height: AppSpace.sm),
              if (tagsStore.secondaryTags.isEmpty)
                Text(
                  'No secondary tags available',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagsStore.secondaryTags.map((tag) {
                    final isSelected =
                        _selectedSecondaryTagIds.contains(tag.id);
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSecondaryTagIds.add(tag.id);
                          } else {
                            _selectedSecondaryTagIds.remove(tag.id);
                          }
                        });
                      },
                      label: Text(
                        tag.name,
                        style: AppTypography.custom(
                          color: isSelected
                              ? AppColors.teal400
                              : AppColors.textMuted,
                          size: AppText.bodySize,
                          weight: FontWeight.w400,
                        ),
                      ),
                      selectedColor: AppColors.teal500.withValues(alpha: 0.15),
                      backgroundColor: AppColors.bgElevated,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.teal500
                            : AppColors.borderSubtle,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              const SizedBox(height: AppSpace.lg),
              _FieldLabel('Title'),
              const SizedBox(height: AppSpace.sm),
              TextFormField(
                controller: _titleController,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
                decoration: _fieldDecoration(hintText: 'Update title'),
                validator: (value) {
                  final next = value?.trim() ?? '';
                  if (next.isEmpty) return 'Title is required';
                  if (next.length < 6) return 'Use at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.lg),
              _FieldLabel('Content'),
              const SizedBox(height: AppSpace.sm),
              TextFormField(
                controller: _contentController,
                minLines: 7,
                maxLines: 12,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
                decoration: _fieldDecoration(
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
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                    decoration: BoxDecoration(
                      gradient: _isSubmitting
                          ? null
                          : LinearGradient(
                              colors: [AppColors.teal500, AppColors.primary500],
                            ),
                      color: _isSubmitting ? AppColors.bgElevated : null,
                      borderRadius: BorderRadius.circular(AppRadius.lgValue),
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
                            'Publish Update',
                            textAlign: TextAlign.center,
                            style: AppTypography.custom(
                              color: Colors.white,
                              size: AppText.bodySize,
                              weight: FontWeight.w600,
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
    return const CustomAppBar(
      title: 'Create Update',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
    );
  }

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.custom(
        color: AppColors.textFaint,
        size: AppText.bodySize,
        weight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.teal500),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.error500),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        borderSide: BorderSide(color: AppColors.error500),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
    );
  }

  /// Date then time. Two steps rather than one, because a window that "closes
  /// Friday" and one that "closes Friday 18:00 UTC" are different promises and
  /// the hunter should have to state which they mean.
  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final seed = _deadlineAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      // A past window is legitimate to report, so yesterday is selectable.
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (!mounted) return;

    setState(() {
      _deadlineAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final updatesStore = context.read<UpdatesStore>();
      final projectsStore = context.read<ProjectsStore>();
      final notificationsStore = context.read<NotificationsStore>();

      final created = await updatesStore.createUpdate(
        projectId: _selectedProjectId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _selectedPriority,
        secondaryTagIds: _selectedSecondaryTagIds.toList(),
        deadlineAt: _deadlineAt,
      );
      if (created == null) {
        throw Exception('Could not create update. Please try again.');
      }

      await Future.wait([
        updatesStore.refreshUpdates(),
        projectsStore.refreshProjects(),
        notificationsStore.refreshNotifications(category: 'all'),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update published')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<Project> _availableProjectsForAuthor({
    required AuthStore auth,
    required List<Project> projects,
  }) {
    if (!_isHunterRestricted(auth)) {
      return projects;
    }

    final userId = auth.userId?.trim() ?? '';
    final username = (auth.username ?? auth.displayName ?? '').trim();

    final filtered = projects.where((project) {
      if (userId.isNotEmpty &&
          (project.adminId == userId || project.admin?.id == userId)) {
        return true;
      }

      final projectUsername =
          project.admin?.username ?? project.admin?.name ?? '';
      return _normalizeIdentity(projectUsername) ==
              _normalizeIdentity(username) &&
          _normalizeIdentity(username).isNotEmpty;
    }).toList(growable: false);

    return filtered;
  }

  bool _isHunterRestricted(AuthStore auth) {
    return auth.isInHunterSpace ||
        (auth.isHunter && !auth.isOwner && !auth.isAdmin);
  }

  String _normalizeIdentity(String value) {
    return value.replaceAll('@', '').trim().toLowerCase();
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
        size: AppText.labelSize,
        weight: FontWeight.w500,
      ),
    );
  }
}

/// Picks the moment a window closes, and shows it back in the same words the
/// feed will use, so a hunter sees what members will read.
class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final at = value;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onPick,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: AppIcon.sm,
                    color: at == null
                        ? AppColors.textFaint
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      at == null
                          ? 'No closing window'
                          : describeDeadline(at, DateTime.now()).label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        color: at == null
                            ? AppColors.textFaint
                            : AppColors.textSecondary,
                        size: AppText.bodySize,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (at != null) ...[
          const SizedBox(width: AppSpace.sm),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.close_rounded,
                size: AppIcon.sm,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
