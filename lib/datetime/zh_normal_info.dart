import 'abs_time_info.dart';

/// * @Author: chuxiong
/// * @Created at: 04-08-2025 10:50
/// * @Email:
/// * description
/// 中文（normal）时间线文案。与 [ZhInfo] 的唯一差异是 [keepTwoDays] 为 `false`，
/// 即 2 天时回退到 `MM-dd`。locale key：`'zh_normal'`。
class ZhNormalInfo implements TimelineInfo {
  @override
  String suffixAgo() => '前';

  @override
  String suffixAfter() => '后';

  @override
  int maxJustNowSecond() => 30;

  @override
  String lessThanOneMinute() => '刚刚';

  @override
  String customYesterday() => '昨天';

  @override
  bool keepOneDay() => true;

  @override
  bool keepTwoDays() => false;

  @override
  String oneMinute(int minutes) => '$minutes分钟';

  @override
  String minutes(int minutes) => '$minutes分钟';

  @override
  String anHour(int hours) => '$hours小时';

  @override
  String hours(int hours) => '$hours小时';

  @override
  String oneDay(int days) => '$days天';

  @override
  String days(int days) => '$days天';
}
