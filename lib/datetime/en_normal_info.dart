import 'abs_time_info.dart';

/// * @Author: chuxiong
/// * @Created at: 04-08-2025 10:50
/// * @Email:
/// * @description
/// 英文（normal）时间线文案。与 [EnInfo] 的唯一差异是 [keepTwoDays] 为 `false`，
/// 即 2 天时回退到 `MM-dd`。locale key：`'en_normal'`。
class EnNormalInfo implements TimelineInfo {
  @override
  String suffixAgo() => ' ago';

  @override
  String suffixAfter() => ' after';

  @override
  int maxJustNowSecond() => 30;

  @override
  String lessThanOneMinute() => 'just now';

  @override
  String customYesterday() => 'Yesterday';

  @override
  bool keepOneDay() => true;

  @override
  bool keepTwoDays() => false;

  @override
  String oneMinute(int minutes) => 'a minute';

  @override
  String minutes(int minutes) => '$minutes minutes';

  @override
  String anHour(int hours) => 'an hour';

  @override
  String hours(int hours) => '$hours hours';

  @override
  String oneDay(int days) => 'a day';

  @override
  String days(int days) => '$days days';
}
