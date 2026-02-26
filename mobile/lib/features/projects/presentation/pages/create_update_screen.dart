import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/tags_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
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
        availableProjects.every((project) => project.id != _selectedProjectId)) {
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
          padding: const EdgeInsets.all(16),
          child: Text(
            'Your current role does not allow creating updates.',
            style: AppTypography.custom(color: AppColors.textMuted,
              size: 13,
              weight: FontWeight.w400,),
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _isHunterRestricted(auth)
                ? 'No projects are assigned to your hunter account yet.'
                : 'No project is available for updates yet.',
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
              _FieldLabel('Project'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.bgElevated,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w400,),
                items: availableProjects
                    .map(
                      (project) => DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(
                          project.name,
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
                  setState(() => _selectedProjectId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FieldLabel('Urgency'),
              const SizedBox(height: 8),
              DropdownButtonFormField<Priority>(
                value: _selectedPriority,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.bgElevated,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w400,),
                items: Priority.getAll()
                    .map(
                      (priority) => DropdownMenuItem<Priority>(
                        value: priority,
                        child: Text(
                          '${priority.label} Urgency',
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
                  setState(() => _selectedPriority = value);
                },
              ),
              const SizedBox(height: 14),
              _FieldLabel('Secondary tags'),
              const SizedBox(height: 8),
              if (tagsStore.secondaryTags.isEmpty)
                Text(
                  'No secondary tags available',
                  style: AppTypography.custom(color: AppColors.textFaint,
                    size: 12,
                    weight: FontWeight.w400,),
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
                        style: AppTypography.custom(color: isSelected
                              ? AppColors.teal400
                              : AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w400,),
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
              const SizedBox(height: 14),
              _FieldLabel('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
                decoration: _fieldDecoration(hintText: 'Update title'),
                validator: (value) {
                  final next = value?.trim() ?? '';
                  if (next.isEmpty) return 'Title is required';
                  if (next.length < 6) return 'Use at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FieldLabel('Content'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                minLines: 7,
                maxLines: 12,
                style: AppTypography.custom(color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w400,),
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
                            'Publish Update',
                            textAlign: TextAlign.center,
                            style: AppTypography.custom(
                              color: Colors.white,
                              size: 14,
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
      hintStyle: AppTypography.custom(color: AppColors.textFaint,
        size: 13,
        weight: FontWeight.w400,),
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
      );
      if (created == null) {
        throw Exception('Could not create update. Please try again.');
      }

      await Future.wait([
        updatesStore.refreshUpdates(),
        projectsStore.refreshProjects(),
        notificationsStore.refreshNotifications(),
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

      final projectUsername = project.admin?.username ?? project.admin?.name ?? '';
      return _normalizeIdentity(projectUsername) == _normalizeIdentity(username) &&
          _normalizeIdentity(username).isNotEmpty;
    }).toList(growable: false);

    return filtered;
  }

  bool _isHunterRestricted(AuthStore auth) {
    return auth.isInHunterSpace || (auth.isHunter && !auth.isOwner && !auth.isAdmin);
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
        size: 12,
        weight: FontWeight.w500,
      ),
    );
  }
}
