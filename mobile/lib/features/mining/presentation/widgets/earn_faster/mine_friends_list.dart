import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_boost_parts.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_earn_faster_cards.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_member_parts.dart';
import 'package:flutter/material.dart';

/// `ACTIVE`, or days since the friend last mined: `12 DAYS`.
String mineFriendPill(DownlineMember friend, DateTime now) {
  if (friend.isActive) return 'ACTIVE';
  final last = friend.lastActiveAt;
  if (last == null) return 'INACTIVE';
  final days = now.toUtc().difference(last.toUtc()).inDays;
  return days == 1 ? '1 DAY' : '$days DAYS';
}

/// The friends card: one row per friend (name, level, active or not) and a
/// footer when someone's boost has lapsed. Never shows emails.
class MineFriendsList extends StatelessWidget {
  const MineFriendsList({
    super.key,
    required this.friends,
    required this.perFriendPercent,
    required this.now,
  });

  final List<DownlineMember> friends;

  /// `+5%`
  final String perFriendPercent;
  final DateTime now;

  static String? footer(List<DownlineMember> friends, String perFriend) {
    final inactive = friends.where((friend) => !friend.isActive).toList();
    if (inactive.isEmpty) return null;
    if (inactive.length == 1) {
      final name = mineMemberName(
        inactive.first.displayName,
        inactive.first.username,
      );
      return "$name's $perFriend counts again when they mine.";
    }
    return 'Inactive friends’ $perFriend counts again when they mine.';
  }

  @override
  Widget build(BuildContext context) {
    final note = footer(friends, perFriendPercent);
    return MineEarnCardFrame(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < friends.length; i++)
            _FriendRow(friend: friends[i], now: now, divided: i > 0),
          if (note != null) MineRuleText(note),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.now,
    required this.divided,
  });

  final DownlineMember friend;
  final DateTime now;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final name = mineMemberName(friend.displayName, friend.username);
    final active = friend.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: divided
            ? const Border(top: BorderSide(color: MinePalette.edge))
            : null,
      ),
      child: Row(
        children: [
          MineAvatar(name: name, imageUrl: friend.avatarUrl),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: MineNameWithLevel(name: name, level: friend.currentLevel),
          ),
          const SizedBox(width: AppSpace.sm),
          MinePill(
            label: mineFriendPill(friend, now),
            tone: active ? MinePalette.accentSoft : MinePalette.faint,
          ),
        ],
      ),
    );
  }
}
