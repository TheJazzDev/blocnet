import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Priority _selectedPriority = Priority.mid;
  String? _selectedProjectId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectsStore = context.read<ProjectsStore>();
      await projectsStore.fetchProjectsOnce();
      if (!mounted) return;

      if (_selectedProjectId == null && projectsStore.projects.isNotEmpty) {
        setState(() {
          _selectedProjectId = projectsStore.projects.first.id;
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

    if (!auth.canCreatePost) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          centerTitle: false,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: StyledBodyText500(
            'Your current role does not allow creating posts.',
          ),
        ),
      );
    }

    if (projectsStore.isFetching && projectsStore.projects.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (projectsStore.projects.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          centerTitle: false,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: StyledBodyText500(
            'No project is available for posting yet.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StyledBodyText500('Project', size: 12),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.darkGrey100,
                items: projectsStore.projects
                    .map(
                      (project) => DropdownMenuItem<String>(
                        value: project.id,
                        child: StyledBodyText600(project.name, size: 13),
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
              const StyledBodyText500('Urgency', size: 12),
              const SizedBox(height: 8),
              DropdownButtonFormField<Priority>(
                value: _selectedPriority,
                decoration: _fieldDecoration(),
                dropdownColor: AppColors.darkGrey100,
                items: Priority.getAll()
                    .map(
                      (priority) => DropdownMenuItem<Priority>(
                        value: priority,
                        child: StyledBodyText600(
                          '${priority.label} Urgency',
                          size: 13,
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
              const StyledBodyText500('Title', size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
                decoration: _fieldDecoration(hintText: 'Post title'),
                validator: (value) {
                  final next = value?.trim() ?? '';
                  if (next.isEmpty) return 'Title is required';
                  if (next.length < 6) return 'Use at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const StyledBodyText500('Content', size: 12),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                minLines: 7,
                maxLines: 12,
                style: TextStyle(color: AppColors.darkGrey700, fontSize: 14),
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
                    _isSubmitting ? 'Publishing...' : 'Publish Post',
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
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final postsStore = context.read<PostsStore>();
      final projectsStore = context.read<ProjectsStore>();
      final notificationsStore = context.read<NotificationsStore>();

      await postsStore.createPost(
        projectId: _selectedProjectId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _selectedPriority,
      );

      await Future.wait([
        postsStore.refreshPosts(),
        projectsStore.refreshProjects(),
        notificationsStore.refreshNotifications(),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
