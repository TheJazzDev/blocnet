part of 'hunter_profile_body.dart';

class _CommunityVoiceSection extends StatelessWidget {
  const _CommunityVoiceSection({
    required this.managedProjects,
    required this.hunterUpdates,
    required this.followersCount,
  });

  final List<Project> managedProjects;
  final List<Update> hunterUpdates;
  final int followersCount;

  @override
  Widget build(BuildContext context) {
    final activeProjects = managedProjects.where((project) {
      return project.posts?.isNotEmpty ?? false;
    }).length;

    final now = DateTime.now();
    final weeklySignals = hunterUpdates.where((update) {
      return now.difference(update.createdAt).inDays < 7;
    }).length;

    final cards = [
      _CommunityMetricCard(
        icon: Icons.people_outline_rounded,
        label: 'Audience Reach',
        value: _compactCount(followersCount),
        text: 'Followers across your profile and projects',
      ),
      _CommunityMetricCard(
        icon: Icons.folder_open_outlined,
        label: 'Projects Managed',
        value: managedProjects.length.toString(),
        text: '$activeProjects have published updates',
      ),
      _CommunityMetricCard(
        icon: Icons.bolt_outlined,
        label: 'Signals This Week',
        value: weeklySignals.toString(),
        text: '${hunterUpdates.length} total updates posted',
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, size: 14, color: AppColors.textFaint),
              const SizedBox(width: 6),
              Text(
                'COMMUNITY VOICE',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, index) => cards[index],
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: cards.length,
          ),
        ),
      ],
    );
  }
}

class _CommunityMetricCard extends StatelessWidget {
  const _CommunityMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String value;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary400),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 22,
              weight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppTypography.custom(color: AppColors.textFaint,
              size: 10,
              weight: FontWeight.w400,
              height: 1.4,),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HunterSignalsSection extends StatelessWidget {
  const _HunterSignalsSection({required this.updates});

  final List<Update> updates;

  @override
  Widget build(BuildContext context) {
    final latestSignals = List<Update>.from(updates)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleSignals = latestSignals.take(2).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'HUNTER SIGNALS',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.manageUpdates),
                child: Text(
                  'View All',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: visibleSignals.isEmpty
              ? _EmptySignalsCard()
              : Column(
                  children: [
                    for (var i = 0; i < visibleSignals.length; i++) ...[
                      _SignalCard(update: visibleSignals[i]),
                      if (i != visibleSignals.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.update});

  final Update update;

  @override
  Widget build(BuildContext context) {
    final projectName = update.project?.name.trim().isNotEmpty == true
        ? update.project!.name.trim()
        : 'Untitled Project';
    final ticker = _deriveTicker(projectName);
    final signalLabel = _prioritySignalLabel(update.priority.label);
    final signalColor = _prioritySignalColor(update.priority.label);
    final summary = _signalBody(update);
    final audience = update.project?.followersCount ?? 0;
    final tagCount = update.secondaryTags.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(Icons.token_outlined,
                    size: 18, color: AppColors.textMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$$ticker · ${getTimeStamp(update.createdAt)}',
                      style: AppTypography.custom(color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w400,),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: signalColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  signalLabel.toUpperCase(),
                  style: AppTypography.custom(
                    color: signalColor,
                    size: 9,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: AppTypography.custom(color: AppColors.textSecondary,
              size: 12,
              weight: FontWeight.w400,
              height: 1.5,),
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _SignalAction(
                icon: Icons.people_outline_rounded,
                count: audience,
              ),
              const SizedBox(width: 16),
              _SignalAction(
                icon: Icons.sell_outlined,
                count: tagCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySignalsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add_outlined, size: 22, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No signals posted yet',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Publish updates to start building your hunter track record.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(color: AppColors.textFaint,
              size: 11,
              weight: FontWeight.w400,),
          ),
        ],
      ),
    );
  }
}

class _SignalAction extends StatelessWidget {
  const _SignalAction({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textFaint),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

String _prioritySignalLabel(String priorityLabel) {
  final normalized = priorityLabel.toLowerCase();
  if (normalized == 'high') return 'Bullish';
  if (normalized == 'mid' || normalized == 'medium') return 'Watch';
  return 'Info';
}

Color _prioritySignalColor(String priorityLabel) {
  final normalized = priorityLabel.toLowerCase();
  if (normalized == 'high') return const Color(0xFF4ADE80);
  if (normalized == 'mid' || normalized == 'medium') {
    return const Color(0xFFFBBF24);
  }
  return AppColors.primary400;
}

String _deriveTicker(String projectName) {
  final words = projectName
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) return 'BNT';

  if (words.length > 1) {
    final ticker = words.map((word) => word[0]).join().toUpperCase();
    return ticker.length > 5 ? ticker.substring(0, 5) : ticker;
  }

  final normalized = words.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (normalized.isEmpty) return 'BNT';
  final length = normalized.length > 5 ? 5 : normalized.length;
  return normalized.substring(0, length).toUpperCase();
}

String _signalBody(Update update) {
  final source = update.content.trim().isNotEmpty
      ? update.content
      : update.description.trim();
  final normalized = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'No additional details provided for this signal.';
  }
  if (normalized.length > 180) {
    return '${normalized.substring(0, 180)}...';
  }
  return normalized;
}
