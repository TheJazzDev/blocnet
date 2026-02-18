import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profile body shown when the user is in Hunter space
/// (owner, admin, or hunter who has toggled to Hunter space).
class HunterProfileBody extends StatelessWidget {
  const HunterProfileBody({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthStore auth;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero ──────────────────────────────────────────────────────────
          _HunterHero(
            displayName: displayName,
            avatarUrl: auth.avatarUrl,
            walletAddress: null,
          ),

          // ── Stats grid ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _HunterStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.primary400,
                  label: 'Success Rate',
                  value: '85%',
                  footnote: 'Last 30 days',
                ),
                const SizedBox(width: 10),
                _HunterStatCard(
                  icon: Icons.thumb_up_alt_outlined,
                  iconColor: const Color(0xFF4ADE80),
                  label: 'Sentiment',
                  value: 'Positive',
                  valueSize: 16,
                  footnote: '142 reviews',
                ),
              ],
            ),
          ),

          // ── Community voice ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Icon(Icons.forum_outlined,
                    size: 14, color: AppColors.textFaint),
                const SizedBox(width: 6),
                Text(
                  'COMMUNITY VOICE',
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _ReviewCard(
                  author: 'Defi_Degen',
                  stars: 5,
                  text: '"Always finds the gems before they pop. Legit calls."',
                ),
                SizedBox(width: 10),
                _ReviewCard(
                  author: 'WhaleWatcher',
                  stars: 4,
                  text: '"Solid analysis, risks are always clearly stated."',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Hunter signals ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'HUNTER SIGNALS',
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColors.primary400,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                _SignalCard(
                  projectName: 'Nexus Protocol',
                  ticker: '\$NEXUS',
                  timeAgo: '2h ago',
                  sentiment: 'Bullish',
                  sentimentColor: Color(0xFF4ADE80),
                  body:
                      'Alpha alert on \$NEXUS. Devs just dropped the roadmap for Q3 and liquidity is locked. Good entry point here before the marketing push.',
                  likes: 24,
                  comments: 8,
                ),
                SizedBox(height: 10),
                _SignalCard(
                  projectName: 'Project Z',
                  ticker: '\$PROJZ',
                  timeAgo: '5h ago',
                  sentiment: 'Hold',
                  sentimentColor: Color(0xFFFBBF24),
                  body:
                      'Volume is consolidating. Waiting for a breakout above the 0.05 resistance level before adding more to my bag. Watch this space.',
                  likes: 156,
                  comments: 42,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Content management ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HunterSectionLabel('Content'),
                const SizedBox(height: 8),
                _HunterTile(
                  icon: Icons.send_outlined,
                  title: 'Submit New Gem',
                  subtitle: 'Send a project for approval before publishing',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.submitProject),
                ),
                _HunterTile(
                  icon: Icons.folder_copy_outlined,
                  title: 'Manage My Gems',
                  subtitle: 'See projects you created or contribute to',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.manageProjects),
                ),
                _HunterTile(
                  icon: Icons.post_add_outlined,
                  title: 'Manage My Updates',
                  subtitle: 'Review and edit your hunter updates',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.manageUpdates),
                ),
                const SizedBox(height: 12),
                _HunterSectionLabel('More'),
                const SizedBox(height: 8),
                _HunterTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'View alerts and activity',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.notifications),
                ),
                _HunterTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Account preferences',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                const SizedBox(height: 12),
                _HunterSectionLabel('Account'),
                const SizedBox(height: 8),
                _HunterTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  iconColor: AppColors.textMuted,
                  titleColor: AppColors.textSecondary,
                  onTap: onSignOut,
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hunter hero — avatar with cyan ring, Hunter badge, inline stats, action btns
// ─────────────────────────────────────────────────────────────────────────────

class _HunterHero extends StatelessWidget {
  const _HunterHero({
    required this.displayName,
    required this.avatarUrl,
    required this.walletAddress,
  });

  final String displayName;
  final String? avatarUrl;
  final String? walletAddress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        children: [
          // Avatar with Hunter badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary400.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
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
              // Hunter badge — bottom right
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.bgBase, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 10, color: Colors.black),
                      const SizedBox(width: 3),
                      Text(
                        'Hunter',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            displayName,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            walletAddress ?? 'No wallet connected',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Specializes in DeFi & L2 Scaling',
            style: GoogleFonts.inter(
              color: AppColors.textFaint,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 12),

          // Followers / Following inline
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InlineStat(value: '2.4k', label: 'Followers'),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.borderSubtle,
              ),
              _InlineStat(value: '185', label: 'Following'),
            ],
          ),

          const SizedBox(height: 16),

          // Follow + Tip buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.borderMuted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Follow',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.payments_outlined,
                        size: 16, color: Colors.black),
                    label: Text(
                      'Tip Hunter',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppColors.textFaint,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-col Hunter stat cards
// ─────────────────────────────────────────────────────────────────────────────

class _HunterStatCard extends StatelessWidget {
  const _HunterStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footnote,
    this.valueSize = 22,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footnote;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                color: AppColors.textFaint,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary400,
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              footnote,
              style: GoogleFonts.inter(
                color: AppColors.textFaint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Community review card (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.author,
    required this.stars,
    required this.text,
  });

  final String author;
  final int stars;
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
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary500.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                author,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 11,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hunter signal card (feed-style update card)
// ─────────────────────────────────────────────────────────────────────────────

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.projectName,
    required this.ticker,
    required this.timeAgo,
    required this.sentiment,
    required this.sentimentColor,
    required this.body,
    required this.likes,
    required this.comments,
  });

  final String projectName;
  final String ticker;
  final String timeAgo;
  final String sentiment;
  final Color sentimentColor;
  final String body;
  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
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
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$ticker · $timeAgo',
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Sentiment badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: sentimentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  sentiment.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: sentimentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _SignalAction(
                  icon: Icons.favorite_border_rounded, count: likes),
              const SizedBox(width: 16),
              _SignalAction(
                  icon: Icons.chat_bubble_outline_rounded, count: comments),
              const Spacer(),
              Icon(Icons.share_outlined,
                  size: 16, color: AppColors.textFaint),
            ],
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
          style: GoogleFonts.inter(
              color: AppColors.textFaint, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label + tile (shared with user body via private copies here)
// ─────────────────────────────────────────────────────────────────────────────

class _HunterSectionLabel extends StatelessWidget {
  const _HunterSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppColors.textFaint,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _HunterTile extends StatelessWidget {
  const _HunterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(icon, size: 17,
                  color: iconColor ?? AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: titleColor ?? AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
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
