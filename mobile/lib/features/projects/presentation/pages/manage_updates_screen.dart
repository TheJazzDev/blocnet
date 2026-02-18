import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
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
                          style: GoogleFonts.inter(
                            color: AppColors.error500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (own.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'You have not created any updates yet.',
                            style: GoogleFonts.inter(
                              color: AppColors.textFaint,
                              fontSize: 13,
                            ),
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
    return AppBar(
      backgroundColor: AppColors.bgBase,
      title: Text(
        'Manage Updates',
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textMuted),
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
    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    update.project?.name ?? 'Project',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    update.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textFaint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
