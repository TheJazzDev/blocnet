import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

/// Colours of the approved Mine design. Reuses [AppColors] where the hex
/// already exists; the rest are the design's own values.
class MinePalette {
  const MinePalette._();

  // Grounds and edges.
  static const Color ground = AppColors.bgBase;
  static const Color card = AppColors.hubCard;
  static const Color cardEdge = AppColors.hubCardEdge;
  static const Color tileEdge = AppColors.hubTileEdge;
  static const Color pausedEdge = AppColors.borderMuted;
  static const Color track = AppColors.hubCardEdge;
  static const Color chip = AppColors.bgElevated;
  static const Color divider = Color(0x12FFFFFF);
  static const Color rowHairline = AppColors.borderFaint;
  static const Color hourHairline = Color(0xFF141417);

  // Accent.
  static const Color fill = AppColors.hunterFill;
  static const Color accent = AppColors.chainIce;
  static const Color accentSoft = AppColors.hunterSoft;
  static const Color readyText = Color(0xFFA5F3FC);
  static const Color accentChip = Color(0x1F22D3EE);
  static const Color readyChip = Color(0x2E22D3EE);

  // Cycle grounds.
  static const Color runTop = Color(0xFF0F1B1F);
  static const Color runBottom = Color(0xFF101113);
  static const Color runEdge = Color(0x2E22D3EE);
  static const Color readyTop = Color(0xFF0F2126);
  static const Color readyBottom = Color(0xFF101214);
  static const Color readyEdgeLow = Color(0x5222D3EE);
  static const Color readyEdgeHigh = Color(0xA322D3EE);
  static const Color soonTop = Color(0xFF1F1A10);
  static const Color soonBottom = Color(0xFF121110);
  static const Color soonEdge = Color(0x52F59E0B);

  // Amber.
  static const Color amber = AppColors.dueAmber;
  static const Color amberText = AppColors.chainBsc;
  static const Color amberChip = Color(0x24F59E0B);
  static const Color onAmber = Color(0xFF1C1204);

  // Text.
  static const Color white = Colors.white;
  static const Color strong = AppColors.zincStrong;
  static const Color body = AppColors.zincBody;
  static const Color soft = Color(0xFFC4C4CC);
  static const Color muted = AppColors.zincMuted;
  static const Color faint = AppColors.zincFaint;
  static const Color dim = AppColors.zincDim;
  static const Color caption = AppColors.zincCaption;
  static const Color quiet = AppColors.zincQuiet;

  // Notices.
  static const Color receiptGround = Color(0xFF0F1B1F);
  static const Color receiptEdge = Color(0x3322D3EE);
  static const Color noticeGround = Color(0xFF141412);
  static const Color noticeEdge = Color(0x33F59E0B);
  static const Color noticeButtonEdge = AppColors.borderMuted;

  // Earn faster.
  static const Color codeGround = Color(0xFF0B0F11);
  static const Color codeEdge = Color(0x2E22D3EE);
  static const Color entryGround = Color(0xFF0D0D0F);

  // Leaderboard.
  static const Color gold = Color(0xFFF0B429);
  static const Color silver = Color(0xFFC0C6CE);
  static const Color bronze = Color(0xFFC97B3C);
  static const Color miningNow = AppColors.currentTick;
  static const Color pinGround = Color(0xF20F1417);
  static const Color pinEdge = Color(0x3822D3EE);

  // Popover.
  static const Color scrim = Color(0xA6000000);
  static const Color popover = AppColors.bgSurface;
  static const Color popoverEdge = Color(0xFF2A2A30);
}
