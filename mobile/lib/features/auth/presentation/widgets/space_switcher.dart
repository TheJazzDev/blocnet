import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// A dropdown menu shown in the app bar for users who have multiple spaces.
/// Allows switching between User, Hunter, and Moderation spaces.
///
/// Only renders when user has more than one available space.
class SpaceSwitcher extends StatelessWidget {
  const SpaceSwitcher({
    super.key,
    this.minimal = true,
  });

  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    // Only show if user has more than one space
    final availableSpaces = _getAvailableSpaces(auth);
    if (availableSpaces.length <= 1) return const SizedBox.shrink();

    final currentSpace = _getCurrentSpace(auth);
    final currentIcon = _getIconForSpace(currentSpace);
    final accent = _getAccentForSpace(currentSpace);

    return Tooltip(
      message: auth.isSwitchingSpace
          ? 'Switching space...'
          : 'Switch space (${_getSpaceLabel(currentSpace)})',
      child: Semantics(
        button: true,
        label: auth.isSwitchingSpace
            ? 'Switching space'
            : 'Switch space, currently in ${_getSpaceLabel(currentSpace)}',
        child: GestureDetector(
          onTap: () {
            if (auth.isSwitchingSpace) return;
            HapticFeedback.selectionClick();
            _showSpaceMenu(context, auth, availableSpaces, currentSpace);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: minimal ? 34 : 38,
            height: minimal ? 34 : 38,
            decoration: minimal
                ? null
                : BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.38),
                      width: 1,
                    ),
                  ),
            child: auth.isSwitchingSpace
                ? SizedBox(
                    width: minimal ? 18 : 14,
                    height: minimal ? 18 : 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                : Icon(
                    currentIcon,
                    size: minimal ? 22 : 18,
                    color: accent,
                  ),
          ),
        ),
      ),
    );
  }

  String _getCurrentSpace(AuthStore auth) {
    if (auth.isInModerationSpace) return 'moderation';
    if (auth.isInHunterSpace) return 'hunter';
    return 'user';
  }

  List<String> _getAvailableSpaces(AuthStore auth) {
    final spaces = ['user'];
    if (auth.hasHunterSpace) spaces.add('hunter');
    if (auth.hasModerationSpace) spaces.add('moderation');
    return spaces;
  }

  IconData _getIconForSpace(String space) {
    switch (space) {
      case 'hunter':
        return Icons.radar_rounded;
      case 'moderation':
        return Icons.shield_rounded;
      case 'user':
      default:
        return Icons.public_rounded;
    }
  }

  String _getSpaceLabel(String space) {
    switch (space) {
      case 'hunter':
        return 'Hunter';
      case 'moderation':
        return 'Moderation';
      case 'user':
      default:
        return 'User';
    }
  }

  String _getSpaceDescription(String space) {
    switch (space) {
      case 'hunter':
        return 'Discover and manage projects';
      case 'moderation':
        return 'Community moderation hub';
      case 'user':
      default:
        return 'Social feed and community';
    }
  }

  Color _getAccentForSpace(String space) {
    switch (space) {
      case 'hunter':
        return AppColors.hunterAccent;
      case 'moderation':
        return AppColors.moderationAccent;
      case 'user':
      default:
        return AppColors.userAccent;
    }
  }

  void _showSpaceMenu(
    BuildContext context,
    AuthStore auth,
    List<String> availableSpaces,
    String currentSpace,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Switch Space',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Space options
              ...availableSpaces.map((space) {
                final isCurrentSpace = space == currentSpace;
                final icon = _getIconForSpace(space);
                final label = _getSpaceLabel(space);
                final description = _getSpaceDescription(space);
                final accent = _getAccentForSpace(space);

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: accent,
                    ),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrentSpace ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: isCurrentSpace
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: accent,
                          size: 22,
                        )
                      : null,
                  onTap: () {
                    if (isCurrentSpace) {
                      Navigator.pop(context);
                      return;
                    }

                    Navigator.pop(context);
                    HapticFeedback.selectionClick();
                    auth.switchSpaceWithTransition(space);
                  },
                );
              }),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
