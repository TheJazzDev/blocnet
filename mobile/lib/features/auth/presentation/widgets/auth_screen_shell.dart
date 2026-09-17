import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The frame every auth screen sits in: a back button, a small brand line,
/// a left-aligned heading and subtitle, then the screen's content in one flat
/// bordered card. The whole page scrolls, so nothing overflows when the
/// keyboard is up on a small phone.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.notice,
    this.appBarTitle,
  });

  final String heading;
  final String subtitle;
  final Widget child;
  final bool showBack;

  /// Sits between the subtitle and the card (e.g. a config warning).
  final Widget? notice;

  /// Optional small title next to the back button. Empty or null hides it.
  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    final title = appBarTitle?.trim() ?? '';
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg + 2,
              AppSpace.xs,
              AppSpace.lg + 2,
              AppSpace.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      if (showBack) const _BackButton(),
                      if (title.isNotEmpty)
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.subtitle(AppColors.textPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
                AppSpace.gapSm,
                const _BrandLine(),
                AppSpace.gapXl,
                Text(heading, style: AppText.headline(AppColors.textPrimary)),
                AppSpace.gapXs,
                Text(subtitle, style: AppText.body(AppColors.textMuted)),
                if (notice != null) ...[
                  AppSpace.gapMd,
                  notice!,
                ],
                AppSpace.gapXl,
                AppSurface(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The logo in a small bordered square, then `BLOCNET` in tracked caps.
class _BrandLine extends StatelessWidget {
  const _BrandLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(AppSpace.sm - 1),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Image.asset('assets/img/logo.png', fit: BoxFit.contain),
        ),
        AppSpace.wGapMd,
        Text(
          'BLOCNET',
          style: AppText.caption(AppColors.textFaint, weight: AppText.bold)
              .copyWith(letterSpacing: 1.0),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textSecondary,
          size: AppIcon.sm,
        ),
      ),
    );
  }
}
