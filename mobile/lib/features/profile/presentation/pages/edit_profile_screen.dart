import 'dart:io';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/features/profile/presentation/widgets/edit_profile/avatar_picker_row.dart';
import 'package:blocnet/features/profile/presentation/widgets/edit_profile/profile_primary_button.dart';
import 'package:blocnet/features/profile/presentation/widgets/edit_profile/profile_text_field.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedAvatarFile;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthStore>();
    _displayNameCtrl = TextEditingController(text: auth.displayName ?? '');
    _bioCtrl = TextEditingController(text: auth.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthStore>();
    if (_selectedAvatarFile != null) {
      final avatarUploaded = await auth.uploadAvatarImage(_selectedAvatarFile!);
      if (!mounted) return;
      if (!avatarUploaded) {
        setState(() => _isSubmitting = false);
        AppSnackbar.showError(
          context,
          auth.lastError ?? 'Could not upload the photo',
        );
        return;
      }
    }

    final success = await auth.updateProfile(
      displayName: _displayNameCtrl.text,
      bio: _bioCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      AppSnackbar.showError(
        context,
        context.read<AuthStore>().lastError ?? 'Could not save your profile',
      );
      return;
    }

    await _refreshDependentViews();
    if (!mounted) return;

    AppSnackbar.showSuccess(context, 'Profile saved');
    Navigator.of(context).pop(true);
  }

  Future<void> _refreshDependentViews() async {
    final futures = <Future<void>>[
      context.read<UserProfileStore>().refreshAll(),
      context.read<UpdatesStore>().refreshUpdates(),
      context.read<ProjectsStore>().refreshProjects(),
      context.read<CommunityPostsStore>().refreshPosts(),
    ];

    await Future.wait(
      futures.map((future) async {
        try {
          await future;
        } catch (_) {
          // Keep profile update successful even if downstream refresh fails.
        }
      }),
    );
  }

  Future<void> _pickAvatar() async {
    if (_isPickingImage || _isSubmitting) return;
    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) {
        return;
      }

      final pickedFile = File(image.path);
      final fileSize = await pickedFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (!mounted) return;
        AppSnackbar.showError(context, 'Photo must be 5 MB or smaller');
        return;
      }

      if (!mounted) return;
      setState(() => _selectedAvatarFile = pickedFile);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Could not open that photo');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final username = auth.username?.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Edit Profile',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Photo'),
                AppSpace.gapSm,
                AvatarPickerRow(
                  name: auth.displayName ?? auth.email ?? '',
                  avatarUrl: auth.avatarUrl,
                  pickedFile: _selectedAvatarFile,
                  isPicking: _isPickingImage,
                  onPick: _isSubmitting ? null : _pickAvatar,
                ),
                AppSpace.gapXl,
                const SectionLabel('Username'),
                AppSpace.gapSm,
                AppSurface(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg, vertical: AppSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          username.isEmpty
                              ? 'Not set'
                              : (username.startsWith('@')
                                  ? username
                                  : '@$username'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(AppColors.textMuted),
                        ),
                      ),
                      Icon(Icons.lock_outline_rounded,
                          size: AppIcon.sm, color: AppColors.textFaint),
                    ],
                  ),
                ),
                AppSpace.gapXs,
                Text(
                  'Set at sign-up. Can’t be changed.',
                  style: AppText.caption(AppColors.textFaint),
                ),
                AppSpace.gapXl,
                const SectionLabel('Display name'),
                AppSpace.gapSm,
                ProfileTextField(controller: _displayNameCtrl),
                AppSpace.gapXl,
                const SectionLabel('Bio'),
                AppSpace.gapSm,
                ProfileTextField(
                  controller: _bioCtrl,
                  minLines: 3,
                  maxLines: 5,
                ),
                AppSpace.gapXl,
                ProfilePrimaryButton(
                  label: 'Save',
                  busy: _isSubmitting,
                  onPressed: _save,
                  foreground: AppColors.onAccentForSpace(auth.isInHunterSpace),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
