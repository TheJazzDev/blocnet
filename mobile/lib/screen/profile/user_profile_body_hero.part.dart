part of 'user_profile_body.dart';

class _UserHero extends StatelessWidget {
  const _UserHero({
    required this.displayName,
    required this.avatarUrl,
    required this.walletAddress,
  });

  final String displayName;
  final String? avatarUrl;
  final String? walletAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal400, AppColors.primary500],
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgBase,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.bgElevated,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.teal400,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgBase, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: walletAddress != null
                        ? const Color(0xFF22C55E)
                        : AppColors.textFaint,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  walletAddress ?? 'No wallet connected',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (walletAddress != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.copy_rounded, size: 13, color: AppColors.textFaint),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textFaint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary400,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadToHunterCard extends StatelessWidget {
  const _RoadToHunterCard({
    required this.progress,
    required this.level,
    required this.onViewRequirements,
  });

  final double progress;
  final int level;
  final VoidCallback onViewRequirements;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgSurface, AppColors.bgElevated],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: AppColors.primary400, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Road to Hunter',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level $level',
                  style: GoogleFonts.inter(
                    color: AppColors.primary400,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Complete tasks to unlock earning potential.',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Progress',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: GoogleFonts.inter(
                  color: AppColors.primary400,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          const _CheckItem(done: true, text: 'Connect Wallet'),
          const SizedBox(height: 8),
          const _CheckItem(done: true, text: 'Complete Profile'),
          const SizedBox(height: 8),
          const _CheckItem(
            done: false,
            step: 3,
            text: 'Engage in 5 Projects',
            suffix: '2/5',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onViewRequirements,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Requirements',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.done,
    required this.text,
    this.step,
    this.suffix,
  });

  final bool done;
  final String text;
  final int? step;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                : Colors.transparent,
            border: done
                ? null
                : Border.all(color: AppColors.borderMuted, width: 1.5),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 13, color: Color(0xFF22C55E))
              : Center(
                  child: Text(
                    step?.toString() ?? '',
                    style: GoogleFonts.inter(
                      color: AppColors.textFaint,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.inter(
            color: done ? AppColors.textMuted : AppColors.textPrimary,
            fontSize: 13,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textMuted,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(
            '($suffix)',
            style: GoogleFonts.inter(
              color: AppColors.textFaint,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
