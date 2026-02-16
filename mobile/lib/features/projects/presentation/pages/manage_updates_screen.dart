import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
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
        appBar: AppBar(title: const Text('Manage Updates'), centerTitle: false),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: StyledBodyText500(
            'Your current role does not allow managing updates.',
          ),
        ),
      );
    }

    return Consumer<UpdatesStore>(
      builder: (context, updatesStore, _) {
        final userId = auth.userId ?? '';
        final ownUpdates = updatesStore.updates
            .where((update) => update.adminId == userId)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Updates'),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: auth.canCreateUpdate
                    ? () =>
                        Navigator.of(context).pushNamed(AppRoutes.createUpdate)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: updatesStore.isFetching && updatesStore.updates.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: updatesStore.refreshUpdates,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (updatesStore.lastError != null &&
                          updatesStore.lastError!.isNotEmpty) ...[
                        StyledBodyText500(
                          updatesStore.lastError!,
                          size: 12,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (ownUpdates.isEmpty)
                        const StyledBodyText500(
                          'You have not created updates yet.',
                          size: 12,
                        )
                      else
                        ...ownUpdates.map(
                          (update) => InkWell(
                            onTap: () => showGeneralDialog<void>(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: 'Dismiss',
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return UpdateDetailsDialog(id: update.id);
                              },
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.darkGrey100,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.darkGrey200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StyledBodyText700(update.title, size: 13),
                                  const SizedBox(height: 4),
                                  StyledBodyText500(
                                    update.project?.name ?? 'Project',
                                    size: 12,
                                  ),
                                  const SizedBox(height: 4),
                                  StyledBodyText500(
                                    update.description,
                                    size: 11,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
