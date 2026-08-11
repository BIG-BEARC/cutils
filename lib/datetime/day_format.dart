/// * @Author: chuxiong
/// * @Created at: 04-08-2025 10:52
/// * @Email:
/// * description
/// (xx)Configurable output.
/// (xx)为可配置输出.
enum DayFormat {
  /// (within just-now threshold -> just now)、x minutes、x hours、(Yesterday)、x days.
  /// (在「刚刚」阈值内 -> 刚刚)、x分钟、x小时、(昨天)、x天.
  ///
  /// 「刚刚」阈值由 [TimelineInfo.maxJustNowSecond] 决定（默认 30 秒）。
  simple,

  /// (within just-now threshold -> just now)、x minutes、x hours、[This year:(Yesterday/a day ago)、(two days age)、MM-dd ]、[past years: yyyy-MM-dd]
  /// (在「刚刚」阈值内 -> 刚刚)、x分钟、x小时、[今年: (昨天/1天前)、(2天前)、MM-dd],[往年: yyyy-MM-dd].
  ///
  /// 「刚刚」阈值由 [TimelineInfo.maxJustNowSecond] 决定（默认 30 秒）。
  common,

  /// 日期 + HH:mm
  /// (within just-now threshold -> just now)、x minutes、x hours、[This year:(Yesterday HH:mm/a day ago)、(two days age)、MM-dd HH:mm]、[past years: yyyy-MM-dd HH:mm]
  /// (在「刚刚」阈值内 -> 刚刚)、x分钟、x小时、[今年: (昨天 HH:mm/1天前)、(2天前)、MM-dd HH:mm],[往年: yyyy-MM-dd HH:mm].
  ///
  /// 「刚刚」阈值由 [TimelineInfo.maxJustNowSecond] 决定（默认 30 秒）。
  full,
}
