/// * @Author: chuxiong
/// * @Created at: 04-08-2025 10:49
/// * @Email:
/// * description
/// Timeline 信息配置：定义「时间线」文案（刚刚 / x 分钟前 / 昨天 等）的多语言
/// 抽象契约。由 [ZhInfo]、[EnInfo]、[ZhNormalInfo]、[EnNormalInfo] 实现，
/// 并可通过 [TimelineUtil.setLocaleInfo] 注册自定义 locale。
abstract class TimelineInfo {
  /// 过去时间的后缀（如中文「前」、英文 `' ago'`）。
  String suffixAgo(); //suffix ago(后缀 后).

  /// 未来时间的后缀（如中文「后」、英文 `' after'`）。
  String suffixAfter(); //suffix after(后缀 前).

  /// 「刚刚」判定的最大秒数（默认 30 秒以内显示「刚刚」）。
  int maxJustNowSecond() => 30; // max just now second.

  /// 「刚刚」/「just now」文案；返回空串表示不显示该项。
  String lessThanOneMinute() => ''; //just now(刚刚).

  /// 自定义「昨天」文案；返回空串表示禁用（优先级高于 [keepOneDay]）。
  String customYesterday() => ''; //Yesterday(昨天).优先级高于keepOneDay

  /// 是否在 1 天时显示「1 天前」样式；为 `false` 时回退到 `MM-dd`。
  bool keepOneDay(); //保持1天,example: true -> 1天前, false -> MM-dd.

  /// 是否在 2 天时显示「2 天前」样式；为 `false` 时回退到 `MM-dd`。
  bool keepTwoDays(); //保持2天,example: true -> 2天前, false -> MM-dd.

  /// 「1 分钟」文案（[minutes] 恒为 1，便于单复数区分）。
  String oneMinute(int minutes); //a minute(1分钟).

  /// 「x 分钟」文案。
  String minutes(int minutes); //x minutes(x分钟).

  /// 「1 小时」文案（[hours] 恒为 1）。
  String anHour(int hours); //an hour(1小时).

  /// 「x 小时」文案。
  String hours(int hours); //x hours(x小时).

  /// 「1 天」文案（[days] 恒为 1）。
  String oneDay(int days); //a day(1天).

  /// 「x 天」文案。
  String days(int days); //x days(x天).
}
