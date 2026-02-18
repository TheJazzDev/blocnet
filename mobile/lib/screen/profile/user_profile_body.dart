import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Profile body shown when the user is in User space (no hunter role, or
/// hunter/admin who has not switched to Hunter space).
class UserProfileBody extends StatefulWidget {
  const UserProfileBody({
    super.key,
    required this.onSignOut,
    required this.auth,
  });

  final VoidCallback onSignOut;
  final AuthStore auth;

  @override
  State<UserProfileBody> createState() => _UserProfileBodyState();
}

class _UserProfileBodyState extends State<UserProfileBody> {
  int _tabIndex = 0; // 0 = Bookmarks, 1 = Watchlist, 2 = History

  @override
  Widget build(BuildContext context) {
    final followingCount =
        context.watch<ProjectsStore>().followedProjectIds.length;
    final auth = widget.auth;

    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero ──────────────────────────────────────────────────────────
          _UserHero(
            displayName: displayName,
            avatarUrl: auth.avatarUrl,
            walletAddress: null, // Wire up when wallet is connected
          ),

          // ── Stats grid ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _StatCard(value: followingCount.toString(), label: 'Following'),
                const SizedBox(width: 10),
                _StatCard(value: '—', label: 'Tips Sent'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Road to Hunter card (always shown for users) ───────────────────
          if (!auth.hasHunterSpace) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RoadToHunterCard(
                progress: 0.65,
                level: 3,
                onViewRequirements: () =>
                    Navigator.of(context).pushNamed(AppRoutes.becomeHunter),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Tabs ──────────────────────────────────────────────────────────
          _ProfileTabBar(
            tabs: const ['Bookmarks', 'Watchlist', 'History'],
            activeIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),

          const SizedBox(height: 12),

          // ── Tab content ───────────────────────────────────────────────────
          if (_tabIndex == 0) const _BookmarksTab(),
          if (_tabIndex == 1) const _WatchlistTab(),
          if (_tabIndex == 2) const _HistoryTab(),

          const SizedBox(height: 16),

          // ── More / Account ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('More'),
                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'View alerts and activity',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.notifications),
                ),
                _ProfileTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Account preferences',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                const SizedBox(height: 12),
                _SectionLabel('Account'),
                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  iconColor: AppColors.textMuted,
                  titleColor: AppColors.textSecondary,
                  onTap: widget.onSignOut,
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
// Hero — centered avatar, name, wallet pill
// ─────────────────────────────────────────────────────────────────────────────

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
          // Avatar with edit button
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

          // Wallet address pill
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

// ─────────────────────────────────────────────────────────────────────────────
// 2-column stat card
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Road to Hunter card
// ─────────────────────────────────────────────────────────────────────────────

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
          colors: [
            AppColors.bgSurface,
            AppColors.bgElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded,
                      color: AppColors.primary400, size: 18),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

          // Progress bar
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary500),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          // Checklist
          _CheckItem(done: true, text: 'Connect Wallet'),
          const SizedBox(height: 8),
          _CheckItem(done: true, text: 'Complete Profile'),
          const SizedBox(height: 8),
          _CheckItem(
            done: false,
            step: 3,
            text: 'Engage in 5 Projects',
            suffix: '2/5',
          ),

          const SizedBox(height: 16),

          // CTA button
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
              ? const Icon(Icons.check_rounded,
                  size: 13, color: Color(0xFF22C55E))
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final i = e.key;
            final label = e.value;
            final isActive = i == activeIndex;
            return GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                margin: const EdgeInsets.only(right: 24),
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isActive ? AppColors.teal400 : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                height: 44,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isActive
                        ? AppColors.teal400
                        : AppColors.textFaint,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab content stubs
// ─────────────────────────────────────────────────────────────────────────────

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _BookmarkItem(
            title: 'Gem Alert: New L2 Launching',
            subtitle: 'Detailed breakdown of the upcoming zkEVM scaling solution.',
            author: '@AlphaHunter',
            tag: 'Analysis',
            timeAgo: '2h ago',
          ),
          _BookmarkItem(
            title: 'Yield Farming Strategy v2',
            subtitle: 'Optimizing stablecoin pairs on Curve for maximum APY.',
            author: '@DeFiDegan',
            tag: 'Strategy',
            timeAgo: '1d ago',
          ),
          const SizedBox(height: 16),
          // Empty-state nudge
          Column(
            children: [
              Icon(Icons.bookmark_add_outlined,
                  size: 36, color: AppColors.textFaint),
              const SizedBox(height: 8),
              Text(
                'Explore more projects to add bookmarks',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  const _BookmarkItem({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.tag,
    required this.timeAgo,
  });

  final String title;
  final String subtitle;
  final String author;
  final String tag;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary500.withValues(alpha: 0.2),
                  AppColors.teal500.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(Icons.article_outlined,
                size: 22, color: AppColors.textFaint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      author,
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          color: AppColors.textFaint,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistTab extends StatelessWidget {
  const _WatchlistTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Icon(Icons.visibility_outlined, size: 36, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No watchlist items yet',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 36, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No activity history yet',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared profile widgets (also used by HunterProfileBody)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
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
