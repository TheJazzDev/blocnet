import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController =
        TextEditingController(text: authProvider.currentUser?.displayName);
    _bioController =
        TextEditingController(text: authProvider.currentUser?.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    try {
      await profileProvider.updateProfile(
        userId: authProvider.currentUser!.id,
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Also update auth provider
      await authProvider.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;

      Helpers.showSuccess(context, 'Profile updated successfully');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Helpers.showError(context, 'Failed to update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: profileProvider.isLoading ? null : _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                          onPressed: () {
                            // TODO: Implement image picker
                            Helpers.showError(
                                context, 'Image upload coming soon!');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 4,
                maxLength: 200,
              ),
              const SizedBox(height: 24),
              if (profileProvider.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
