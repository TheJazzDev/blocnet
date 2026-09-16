import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';

/// The referral boost as the config defines it. Every figure is derived from
/// the admin-settable config, never a baked-in 5 % or 100 %.
class MineBoost {
  const MineBoost({
    required this.config,
    required this.activeFriends,
    required this.boostBps,
  });

  /// Boost the config grants for [activeFriends] right now.
  factory MineBoost.forFriends(MiningConfigModel config, int activeFriends) {
    final raw = activeFriends * config.perActiveReferralBoostBps;
    return MineBoost(
      config: config,
      activeFriends: activeFriends,
      boostBps: raw.clamp(0, config.maxBoostBps),
    );
  }

  final MiningConfigModel config;
  final int activeFriends;
  final int boostBps;

  bool get hasBoost => boostBps > 0;

  /// `+10%`
  String get percent => MineFormat.boostPercent(boostBps);

  /// `+5%`
  String get perFriendPercent =>
      MineFormat.boostPercent(config.perActiveReferralBoostBps);

  /// `+100%`
  String get maxPercent => MineFormat.boostPercent(config.maxBoostBps);

  /// Meter segments: one per friend the cap allows (20 at 5 % / 100 %).
  int get segments {
    final per = config.perActiveReferralBoostBps;
    if (per <= 0) return 0;
    return (config.maxBoostBps / per).ceil().clamp(0, 50);
  }

  int get filledSegments {
    final per = config.perActiveReferralBoostBps;
    if (per <= 0) return 0;
    return (boostBps / per).floor().clamp(0, segments);
  }

  /// `+10% from 2 friends` / `+5% from 1 friend` / `No boost yet`
  String get sideLine {
    if (!hasBoost) return 'No boost yet';
    return '$percent from ${friends(activeFriends)}';
  }

  /// `2 active friends · +10%`
  String get rowTitle => '${activeFriendsLabel(activeFriends)} · $percent';

  /// `2 active friends · max +100%`
  String get boostCaption =>
      '${activeFriendsLabel(activeFriends)} · max $maxPercent';

  /// `+5% per active friend, max +100%`
  String get perFriendRule =>
      '$perFriendPercent per active friend, max $maxPercent';

  /// BNP a cycle pays with this boost: 120 → 132 at +10 %.
  int pointsPerCycle() => cyclePoints(config.basePointsPerCycle, boostBps);

  /// BNP a cycle would pay with one more active friend.
  int pointsPerCycleWithOneMore() => MineBoost.forFriends(
        config,
        activeFriends + 1,
      ).pointsPerCycle();

  /// Base (unboosted) hourly rate: `5`.
  String get baseRate {
    final hours = config.cycleHours <= 0 ? 24 : config.cycleHours;
    return MineFormat.rate(config.basePointsPerCycle / hours);
  }

  /// `a day` for a 24-hour cycle, `a cycle` otherwise.
  String get perCycleUnit => config.cycleHours == 24 ? 'a day' : 'a cycle';

  static int cyclePoints(int base, int boostBps) =>
      (base * (10000 + boostBps) / 10000).round();

  static String friends(int count) =>
      count == 1 ? '1 friend' : '$count friends';

  static String activeFriendsLabel(int count) =>
      count == 1 ? '1 active friend' : '$count active friends';
}
