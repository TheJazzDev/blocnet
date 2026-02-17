import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FollowBottomSheet extends StatefulWidget {
  const FollowBottomSheet({super.key});

  @override
  State<FollowBottomSheet> createState() => _FollowBottomSheetState();
}

class _FollowBottomSheetState extends State<FollowBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildBottomSheetContent()]);
  }

  Widget _buildBottomSheetContent() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: AppColors.bgSurface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  splashColor: AppColors.teal500.withValues(alpha: 0.1),
                  highlightColor: AppColors.bgElevated,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.adaptive_audio_mic_off,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unfollow',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
