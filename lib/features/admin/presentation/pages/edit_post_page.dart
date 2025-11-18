import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../providers/admin_provider.dart';
import '../../../projects/data/models/post_model.dart';
import '../../../projects/data/models/post_type_model.dart';
import '../../../../core/utils/helpers.dart';

class EditPostPage extends StatefulWidget {
  final Post post;

  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;
  late quill.QuillController _quillController;
  late PostType _selectedType;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _imageUrlController = TextEditingController(text: widget.post.image ?? '');
    _selectedType = widget.post.type;

    // Initialize Quill controller with existing content
    final doc = quill.Document()..insert(0, widget.post.content);
    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.read<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : () => _updatePost(adminProvider),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Post Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Likes', widget.post.likesCount.toString()),
                    _buildStatColumn('Comments', widget.post.commentsCount.toString()),
                    _buildStatColumn('Views', widget.post.viewsCount.toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Post Type Selector
            const Text(
              'Post Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PostType>(
              segments: const [
                ButtonSegment(
                  value: PostType.update,
                  label: Text('Update'),
                  icon: Icon(Icons.update),
                ),
                ButtonSegment(
                  value: PostType.announcement,
                  label: Text('Announcement'),
                  icon: Icon(Icons.campaign),
                ),
                ButtonSegment(
                  value: PostType.urgent,
                  label: Text('Urgent'),
                  icon: Icon(Icons.priority_high),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<PostType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 24),

            // Rich Text Editor
            const Text(
              'Content',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: quill.QuillToolbar.simple(
                      controller: _quillController,
                    ),
                  ),
                  const Divider(height: 1),
                  // Editor
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(12),
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Updating this post will notify all followers about the changes.',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _updatePost(adminProvider),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _updatePost(AdminProvider adminProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get content from Quill editor
    final content = _quillController.document.toPlainText().trim();
    if (content.isEmpty) {
      Helpers.showSnackBar(
        context,
        'Please enter post content',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await adminProvider.updatePost(
      postId: widget.post.id,
      projectId: widget.post.projectId,
      title: _titleController.text.trim(),
      content: content,
      type: _selectedType,
      image: _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(
          context,
          'Post updated successfully!',
        );
        Navigator.pop(context);
      } else {
        Helpers.showSnackBar(
          context,
          'Failed to update post: ${adminProvider.error}',
          isError: true,
        );
      }
    }
  }
}
