part of 'hunter_profile_body.dart';

class _CommunityVoiceSection extends StatelessWidget {
  const _CommunityVoiceSection();

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}

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

class _HunterSignalsSection extends StatelessWidget {
  const _HunterSignalsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.manageUpdates),
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
      ],
    );
  }
}

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: sentimentColor.withValues(alpha: 0.25)),
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
              _SignalAction(icon: Icons.favorite_border_rounded, count: likes),
              const SizedBox(width: 16),
              _SignalAction(
                  icon: Icons.chat_bubble_outline_rounded, count: comments),
              const Spacer(),
              Icon(Icons.share_outlined, size: 16, color: AppColors.textFaint),
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
          style: GoogleFonts.inter(color: AppColors.textFaint, fontSize: 11),
        ),
      ],
    );
  }
}
