import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class TopHuntersScreen extends StatefulWidget {
  const TopHuntersScreen({super.key});

  @override
  State<TopHuntersScreen> createState() => _TopHuntersScreenState();
}

class _TopHuntersScreenState extends State<TopHuntersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UpdatesStore>().fetchUpdatesOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Top Hunters',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<UpdatesStore>(
        builder: (context, store, _) {
          if (store.isFetching && store.posts.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }

          final entries = _buildEntries(store.posts);
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'No hunter data available yet.',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.borderSubtle, height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HunterListTile(
                rank: index + 1,
                entry: entry,
              );
            },
          );
        },
      ),
    );
  }

  List<_HunterEntry> _buildEntries(List<Update> posts) {
    final byAdmin = <String, _HunterAccumulator>{};

    for (final post in posts) {
      final admin = post.admin;
      if (admin == null) continue;
      final accumulator =
          byAdmin.putIfAbsent(admin.id, () => _HunterAccumulator(admin));
      accumulator.count += 1;
      if (post.createdAt.isAfter(accumulator.lastCreatedAt)) {
        accumulator.lastCreatedAt = post.createdAt;
      }
    }

    final entries = byAdmin.values
        .map(
          (value) => _HunterEntry(
            admin: value.admin,
            updatesCount: value.count,
            lastUpdateAt: value.lastCreatedAt,
          ),
        )
        .toList();

    entries.sort((a, b) {
      final byCount = b.updatesCount.compareTo(a.updatesCount);
      if (byCount != 0) return byCount;
      return b.lastUpdateAt.compareTo(a.lastUpdateAt);
    });

    return entries;
  }
}

class _HunterAccumulator {
  _HunterAccumulator(this.admin);

  final Admin admin;
  int count = 0;
  DateTime lastCreatedAt = DateTime.fromMillisecondsSinceEpoch(0);
}

class _HunterEntry {
  const _HunterEntry({
    required this.admin,
    required this.updatesCount,
    required this.lastUpdateAt,
  });

  final Admin admin;
  final int updatesCount;
  final DateTime lastUpdateAt;
}

class _HunterListTile extends StatelessWidget {
  const _HunterListTile({
    required this.rank,
    required this.entry,
  });

  final int rank;
  final _HunterEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      onTap: () => PublicProfileScreen.showSheet(context, entry.admin),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '#$rank',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 11,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgElevated,
            backgroundImage: entry.admin.imageUrl.isNotEmpty
                ? NetworkImage(entry.admin.imageUrl)
                : null,
            child: entry.admin.imageUrl.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  )
                : null,
          ),
        ],
      ),
      title: Text(
        entry.admin.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: 13,
          weight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${entry.updatesCount} updates',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: 11,
          weight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textFaint,
        size: 18,
      ),
    );
  }
}
