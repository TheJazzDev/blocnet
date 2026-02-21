import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

/// Screen showing the requirements to become a Hunter,
/// with progress bars for each eligibility criteria.
class BecomeHunterScreen extends StatelessWidget {
  const BecomeHunterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _BecomeHunterAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(),
            const SizedBox(height: 28),
            Text(
              'ELIGIBILITY REQUIREMENTS',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _RequirementCard(
              icon: Icons.military_tech_outlined,
              iconColor: const Color(0xFFFFD700),
              title: 'Veteran Status',
              description:
                  'Be an active member of the Blocnet community for at least 30 days.',
              progress: 0.85,
              progressLabel: '25 of 30 days',
              met: false,
            ),
            const SizedBox(height: 10),
            _RequirementCard(
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.primary400,
              title: 'Hype Contributions',
              description:
                  'React to or engage with at least 50 project updates.',
              progress: 1.0,
              progressLabel: '63 contributions',
              met: true,
            ),
            const SizedBox(height: 10),
            _RequirementCard(
              icon: Icons.quiz_outlined,
              iconColor: AppColors.tagPartnership,
              title: 'Gem Discovery Quiz',
              description:
                  'Pass the Hunter certification quiz to prove your research skills.',
              progress: 0.0,
              progressLabel: 'Not started',
              met: false,
              actionLabel: 'Take Quiz',
              onAction: () {},
            ),
            const SizedBox(height: 28),
            _InfoBox(
              icon: Icons.info_outline_rounded,
              text:
                  'Once all requirements are met, your application will be reviewed '
                  'by the Blocnet team within 3–5 business days.',
            ),
            const SizedBox(height: 28),
            _ApplyButton(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────

class _BecomeHunterAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Become a Hunter',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 17,
                    weight: FontWeight.w700,
                    letterSpacing: -0.3,
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.1),
            AppColors.primary500.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.radar_rounded,
              color: AppColors.primary400,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Join the Hunter Network',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 18,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hunters are vetted community members who submit and track gem projects. '
            'Earn \$BNT tips from the community for your alpha intel.',
            style: AppTypography.custom(color: AppColors.textSecondary,
              size: 13,
              weight: FontWeight.w400,
              height: 1.5,),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Perk(icon: Icons.diamond_outlined, label: 'Earn Tips'),
              const SizedBox(width: 12),
              _Perk(icon: Icons.bar_chart_rounded, label: 'Track Stats'),
              const SizedBox(width: 12),
              _Perk(icon: Icons.verified_rounded, label: 'Get Verified'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.primary400),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.primary400,
            size: 11,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Requirement card with progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.progress,
    required this.progressLabel,
    required this.met,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final double progress;
  final String progressLabel;
  final bool met;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final barColor = met ? AppColors.successColor : AppColors.primary500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: met
              ? AppColors.successColor.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (met)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 11, color: AppColors.successColor),
                      const SizedBox(width: 3),
                      Text(
                        'Met',
                        style: AppTypography.custom(
                          color: AppColors.successColor,
                          size: 10,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTypography.custom(color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w400,
              height: 1.5,),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                progressLabel,
                style: AppTypography.custom(color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w400,),
              ),
              const Spacer(),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    actionLabel!,
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 11,
                      weight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Info box
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.custom(color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
                height: 1.5,),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply button
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: null, // Disabled until all requirements are met
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          disabledBackgroundColor: AppColors.bgElevated,
          disabledForegroundColor: AppColors.textFaint,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          'Apply to Become a Hunter',
          style: AppTypography.custom(size: 14,
            color: Colors.black,
            weight: FontWeight.w700,),
        ),
      ),
    );
  }
}
