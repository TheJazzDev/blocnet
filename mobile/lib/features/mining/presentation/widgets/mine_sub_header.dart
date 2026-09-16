import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:flutter/material.dart';

/// Sub-screen header: back arrow and a 17 px title, 48 tall.
class MineSubHeader extends StatelessWidget implements PreferredSizeWidget {
  const MineSubHeader({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MinePalette.ground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: AppSpace.xs),
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: AppIcon.md,
                  color: MinePalette.muted,
                ),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle(
                      MinePalette.white,
                      weight: AppText.bold,
                    ).copyWith(letterSpacing: -0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
