import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/services/projects/project_invites_store.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pending project invites for the current hunter with Accept / Decline.
/// Renders nothing when there is nothing to show.
class ProjectInvitesSection extends StatelessWidget {
  const ProjectInvitesSection({super.key});

  Future<void> _respond(
    BuildContext context,
    ProjectInviteModel invite, {
    required bool accept,
  }) async {
    final store = context.read<ProjectInvitesStore>();
    final projectsStore = context.read<ProjectsStore>();
    final ok = await store.respond(invite.id, accept: accept);
    if (!context.mounted) return;

    if (ok && accept) {
      // The gem is now assigned to this hunter; refresh so it shows up in
      // Manage My Gems and the Create Update picker.
      projectsStore.refreshProjects();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok
              ? (accept ? AppColors.successColor : AppColors.bgElevated)
              : AppColors.error500,
          content: Text(
            ok
                ? (accept
                    ? 'You now hunt ${invite.projectName}.'
                    : 'Invite for ${invite.projectName} declined.')
                : (store.lastError ?? 'Could not respond to the invite.'),
            style: AppTypography.custom(
              color: Colors.white,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectInvitesStore>();
    final pending = store.pendingInvites;
    final error = store.lastError;

    if (pending.isEmpty && (error == null || store.hasLoaded)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Invites',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.labelSize,
                  weight: FontWeight.w700,
                ),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: AppSpace.hair),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                  ),
                  child: Text(
                    '${pending.length}',
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: AppText.captionSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (pending.isEmpty && error != null)
            _InvitesErrorRow(
              message: error,
              onRetry: () => store.loadMine(force: true),
            )
          else
            for (final invite in pending)
              _InviteCard(
                invite: invite,
                busy: store.isResponding(invite.id),
                onAccept: () => _respond(context, invite, accept: true),
                onDecline: () => _respond(context, invite, accept: false),
              ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ProjectInviteModel invite;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final note = invite.note;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: AppIcon.md,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.projectName,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.bodySize,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      'Invited to hunt this gem · ${getTimeStamp(invite.createdAt)}',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: AppText.captionSize,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
              ),
              child: Text(
                note,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.borderMuted),
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: AppTypography.custom(
                      size: AppText.labelSize,
                      weight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Accept',
                          style: AppTypography.custom(
                            size: AppText.labelSize,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvitesErrorRow extends StatelessWidget {
  const _InvitesErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: AppTypography.custom(
              color: AppColors.error500,
              size: AppText.captionSize,
              weight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
