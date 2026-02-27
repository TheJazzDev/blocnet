import 'dart:io';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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
          auth.lastError ?? 'Failed to upload avatar',
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
        context.read<AuthStore>().lastError ?? 'Failed to update profile',
      );
      return;
    }

    AppSnackbar.showSuccess(context, 'Profile updated successfully');
    Navigator.of(context).pop(true);
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
        AppSnackbar.showError(context, 'Avatar must be 5MB or smaller');
        return;
      }

      if (!mounted) return;
      setState(() => _selectedAvatarFile = pickedFile);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(
          context, 'Image selection failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Avatar'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgSurface,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedAvatarFile != null
                          ? Image.file(
                              _selectedAvatarFile!,
                              fit: BoxFit.cover,
                            )
                          : (auth.avatarUrl != null &&
                                  auth.avatarUrl!.trim().isNotEmpty
                              ? Image.network(
                                  auth.avatarUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : Icon(Icons.person, color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: _isPickingImage ? null : _pickAvatar,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isPickingImage ? 'Opening...' : 'Choose image',
                            style: AppTypography.custom(
                              color: AppColors.textSecondary,
                              size: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FieldLabel('Username'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    auth.username ?? '@set-at-signup',
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: 13,
                      weight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Username is unique and cannot be changed after signup.',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 11,
                    weight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Display Name'),
                const SizedBox(height: 6),
                _Input(ctrl: _displayNameCtrl),
                const SizedBox(height: 16),
                _FieldLabel('Bio'),
                const SizedBox(height: 6),
                _Input(ctrl: _bioCtrl, minLines: 3, maxLines: 5),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      disabledBackgroundColor:
                          AppColors.primary500.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Profile',
                            style: AppTypography.custom(
                              size: 13,
                              color: Colors.black,
                              weight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.custom(
        color: AppColors.textMuted,
        size: 11,
        weight: FontWeight.w600,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.ctrl,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController ctrl;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      minLines: minLines,
      maxLines: maxLines,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: AppTypography.custom(
        color: AppColors.textSecondary,
        size: 13,
        weight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bgSurface,
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
          borderSide: BorderSide(color: AppColors.primary400, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
