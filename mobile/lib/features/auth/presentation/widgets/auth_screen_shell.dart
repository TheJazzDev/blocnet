import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

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
  final Widget? notice;
  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // ── Layer 1: Deep background ──────────────────────────
          const Positioned.fill(child: _DeepBackground()),

          // ── Layer 2: Decorative grid mesh ─────────────────────
          const Positioned.fill(child: _GridMesh()),

          // ── Layer 3: Content ──────────────────────────────────
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.sm, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child:
                              showBack ? const _BackButton() : const SizedBox(),
                        ),
                        Expanded(
                          child: Text(
                            appBarTitle ?? 'Blocnet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppText.titleSize,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: _LogoMark(),
                  ),

                  // Heading + subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _GradientHeading(heading),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppText.bodySize,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w400,
                            height: 1.55,
                          ),
                        ),
                        if (notice != null) ...[
                          const SizedBox(height: AppSpace.md),
                          notice!,
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.xl),

                  // Form card — frosted dark panel
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                      child: _FormCard(child: child),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background layers
// ─────────────────────────────────────────────────────────────────────────────

class _DeepBackground extends StatelessWidget {
  const _DeepBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark canvas
        Container(color: AppColors.bgBase),

        // Top-left teal orb
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary500.withValues(alpha: 0.24),
                  AppColors.primary500.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Top-right blue orb
        Positioned(
          top: -60,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary700.withValues(alpha: 0.24),
                  AppColors.primary700.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Bottom center subtle teal bleed
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary700.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridMesh extends StatelessWidget {
  const _GridMesh();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.55)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 40.0;

    // Vertical lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo mark — centered, glow ring only (no wordmark text)
// ─────────────────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary400.withValues(alpha: 0.22),
                  AppColors.primary700.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Logo container
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.lgValue),
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.primary700.withValues(alpha: 0.15),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpace.md),
            child: Image.asset(
              'assets/img/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient heading text (teal → blue)
// ─────────────────────────────────────────────────────────────────────────────

class _GradientHeading extends StatelessWidget {
  const _GradientHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.textPrimary,
          AppColors.primary300.withValues(alpha: 0.9),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppText.headlineSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Britti',
          letterSpacing: -0.3,
          height: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted dark form card
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28));

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          // Base card
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: radius,
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, 28, AppSpace.xl, AppSpace.xxl),
              child: child,
            ),
          ),

          // Teal top accent line (drawn on top, uniform width)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary500.withValues(alpha: 0.5),
                    AppColors.primary700.withValues(alpha: 0.32),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back button
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xlValue),
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary,
            size: AppIcon.sm,
          ),
        ),
      ),
    );
  }
}
