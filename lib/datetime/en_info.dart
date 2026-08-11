import 'abs_time_info.dart';

/// * @Author: chuxiong
/// * @Created at: 04-08-2025 10:49
/// * @Email:
/// * description
/// 英文时间线文案。`keepOneDay` / `keepTwoDays` 均为 `true`。locale key：`'en'`。
class EnInfo implements TimelineInfo {
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
  bool keepTwoDays() => true;

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
