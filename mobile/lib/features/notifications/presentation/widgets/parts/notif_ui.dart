import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Text colour that reads on a filled [accent]: black on the cyan hunter
/// accent, white on the blue user or red moderation accent.
Color notifOnAccent(Color accent) =>
    accent.computeLuminance() > 0.4 ? Colors.black : Colors.white;

/// 10px bold caps label in [color] with 1.0 letter-spacing.
TextStyle notifCaps(Color color) =>
    AppText.caption(color, weight: AppText.bold).copyWith(letterSpacing: 1.0);

/// Flat card: surface ground, 1px subtle edge, [AppRadius.md].
BoxDecoration notifCardDecoration({Color? ground}) => BoxDecoration(
      color: ground ?? AppColors.bgSurface,
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.borderSubtle),
    );

/// Outlined pill: faint tint, coloured hairline, coloured caps text.
class NotifPill extends StatelessWidget {
  const NotifPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: notifCaps(color).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

/// Tinted icon square used at the head of list rows.
class NotifIconSquare extends StatelessWidget {
  const NotifIconSquare({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, size: AppIcon.sm, color: color),
    );
  }
}

/// 44px button: filled in [accent], or dark outlined when [accent] is null.
class NotifButton extends StatelessWidget {
  const NotifButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.accent,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fill = accent;
    final foreground =
        fill == null ? AppColors.textPrimary : notifOnAccent(fill);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      backgroundColor:
          WidgetStatePropertyAll(fill ?? AppColors.bgElevated),
      foregroundColor: WidgetStatePropertyAll(foreground),
      side: WidgetStatePropertyAll(
        fill == null ? BorderSide(color: AppColors.borderMuted) : null,
      ),
      textStyle: WidgetStatePropertyAll(
        AppText.body(foreground, weight: AppText.bold),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: text);
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: AppIcon.sm),
      label: text,
    );
  }
}
