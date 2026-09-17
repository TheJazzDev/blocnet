import 'dart:io';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

/// Current (or newly picked) avatar with a Change button.
class AvatarPickerRow extends StatelessWidget {
  const AvatarPickerRow({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.pickedFile,
    required this.isPicking,
    required this.onPick,
  });

  final String name;
  final String? avatarUrl;
  final File? pickedFile;
  final bool isPicking;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final picked = pickedFile;
    return Row(
      children: [
        if (picked != null)
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: Image.file(picked, fit: BoxFit.cover),
          )
        else
          ProfileAvatar(name: name, imageUrl: avatarUrl, size: 56),
        AppSpace.wGapMd,
        OutlinedButton.icon(
          onPressed: isPicking ? null : onPick,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 40),
            side: const BorderSide(color: AppColors.borderMuted),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          ),
          icon: Icon(
            Icons.image_outlined,
            size: AppIcon.sm,
            color: AppColors.textMuted,
          ),
          label: Text(
            isPicking ? 'Opening…' : 'Change photo',
            style:
                AppText.label(AppColors.textPrimary, weight: AppText.semibold),
          ),
        ),
      ],
    );
  }
}
