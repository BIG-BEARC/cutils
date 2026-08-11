import 'abs_time_info.dart';

/// * @Author: chuxiong
/// * @Created at: 04-08-2025 10:49
/// * @Email:
/// * description
/// 中文时间线文案。`keepOneDay` / `keepTwoDays` 均为 `true`，因此 1~2 天
/// 会显示「x天前」样式。locale key：`'zh'`。
class ZhInfo implements TimelineInfo {
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
  bool keepTwoDays() => true;

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
