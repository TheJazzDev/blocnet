import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class ManageUpdatesScreen extends StatefulWidget {
  const ManageUpdatesScreen({super.key});

  @override
  State<ManageUpdatesScreen> createState() => _ManageUpdatesScreenState();
}

class _ManageUpdatesScreenState extends State<ManageUpdatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatesStore>().fetchUpdatesOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (!auth.canCreateUpdate) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _appBar(context, showAdd: false),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Your current role does not allow managing updates.',
            style: AppTypography.custom(color: AppColors.textMuted,
              size: 14,
              weight: FontWeight.w400,),
          ),
        ),
      );
    }

    return Consumer<UpdatesStore>(
      builder: (context, store, _) {
        final userId = auth.userId ?? '';
        final own = store.updates.where((u) => u.adminId == userId).toList();

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: _appBar(context, showAdd: true),
          body: store.isFetching && store.updates.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal400,
                    strokeWidth: 2,
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.teal400,
                  backgroundColor: AppColors.bgSurface,
                  onRefresh: store.refreshUpdates,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (store.lastError != null &&
                          store.lastError!.isNotEmpty) ...[
                        Text(
                          store.lastError!,
                          style: AppTypography.custom(color: AppColors.error500,
                            size: 12,
                            weight: FontWeight.w400,),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (own.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'You have not created any updates yet.',
                            style: AppTypography.custom(color: AppColors.textFaint,
                              size: 13,
                              weight: FontWeight.w400,),
                          ),
                        )
                      else
                        ...own.map((update) => _UpdateTile(update: update)),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, {required bool showAdd}) {
    return CustomAppBar(
      title: 'Manage Updates',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
      actions: [
        if (showAdd)
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.createUpdate),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Icon(Icons.add, size: 18, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

// ─── Update Tile ──────────────────────────────────────────────────────────────

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.update});

  final Update update;

  void _openDetails(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UpdateDetailsDialog(id: update.id);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = update.priority.color;

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priorityColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: priorityColor.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    priorityColor.withValues(alpha: 0.2),
                    priorityColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: priorityColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.campaign_rounded,
                size: 20,
                color: priorityColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          update.title,
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: priorityColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              update.priority.label.toUpperCase(),
                              style: AppTypography.custom(
                                color: priorityColor,
                                size: 9,
                                weight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 12,
                        color: AppColors.textFaint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        update.project?.name ?? 'Project',
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    update.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 12,
                      weight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
