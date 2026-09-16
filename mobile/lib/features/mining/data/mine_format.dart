import 'package:blocnet/shared/utils/format_number_utils.dart';

/// Number and time formatting for the Mine tab, in the design's patterns:
/// `09:20`, `Fri 15:20`, `14 Sep`, `8,412`.
///
/// Times are shown in the device's local zone. The design writes 24-hour
/// clock times everywhere, so they are not localised to a 12-hour clock.
class MineFormat {
  const MineFormat._();

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// `8,412` — whole BNP.
  static String points(num value) =>
      formatGroupedNumber(value.floor(), maxDecimals: 0);

  /// `5.5` / `5` — hourly amounts keep up to two decimals.
  static String rate(num value) =>
      formatGroupedNumber(value, maxDecimals: 2, minDecimals: 0);

  /// `+10%` from basis points.
  static String boostPercent(int bps) => '+${rate(bps / 100)}%';

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// `09:20`
  static String clock(DateTime time) {
    final local = time.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// `09:00` — the hour a checkpoint started.
  static String hour(DateTime time) => '${_two(time.toLocal().hour)}:00';

  /// `Fri`
  static String weekday(DateTime time) => _weekdays[time.toLocal().weekday - 1];

  /// `Fri 15:20`
  static String weekdayClock(DateTime time) =>
      '${weekday(time)} ${clock(time)}';

  /// `14 Sep`
  static String dayMonth(DateTime time) {
    final local = time.toLocal();
    return '${local.day} ${_months[local.month - 1]}';
  }

  /// Whole local days from [now] to [time]: 0 today, 1 tomorrow.
  static int dayGap(DateTime time, DateTime now) {
    final a = time.toLocal();
    final b = now.toLocal();
    final dayA = DateTime(a.year, a.month, a.day);
    final dayB = DateTime(b.year, b.month, b.day);
    // Rounded so a DST day (23 or 25 hours) still counts as one.
    return (dayA.difference(dayB).inHours / 24).round();
  }

  /// `today` / `tomorrow` / `Fri`
  static String relativeDay(DateTime time, DateTime now) {
    final gap = dayGap(time, now);
    if (gap <= 0) return 'today';
    if (gap == 1) return 'tomorrow';
    return weekday(time);
  }

  /// `15h` or, under an hour, `40m`. Rounded up so "0" never shows while
  /// time remains.
  static String shortDuration(Duration left) {
    if (left.inSeconds <= 0) return '0m';
    if (left < const Duration(hours: 1)) {
      final minutes = (left.inSeconds / 60).ceil();
      return '${minutes}m';
    }
    final hours = (left.inMinutes / 60).ceil();
    return '${hours}h';
  }
}
