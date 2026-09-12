// ignore_for_file: non_constant_identifier_names, constant_identifier_names
/// * @Author: chuxiong
/// * @Created at: 23-07-2025 16:56
/// * @Email:
/// * description 一些常用格式参照。如果下面格式不够，你可以自定义。
/// 日期格式常量集，供 [DateTimeUtils.formatDate] 的 `format` 参数使用。
class DateFormats {
  /// `yyyy-MM-dd HH:mm:ss`（标准全格式）。
  static const String FULL = 'yyyy-MM-dd HH:mm:ss';

  /// `yyyy-MM-dd HH:mm`（到分钟）。
  static const String Y_M_D_H_M = 'yyyy-MM-dd HH:mm';

  /// `yyyy-MM-dd`（仅日期）。
  static const String Y_M_D = 'yyyy-MM-dd';

  /// `yyyy-MM`（仅年月）。
  static const String Y_M = 'yyyy-MM';

  /// `MM-dd`（月日）。
  static const String M_D = 'MM-dd';

  /// `MM-dd HH:mm`（月日时分）。
  static const String M_D_H_M = 'MM-dd HH:mm';

  /// `HH:mm:ss`（时分秒）。
  static const String H_M_S = 'HH:mm:ss';

  /// `HH:mm`（时分）。
  static const String H_M = 'HH:mm';

  /// `yyyy年MM月dd日 HH时mm分ss秒`（中文全格式）。
  static const String ZH_FULL = 'yyyy年MM月dd日 HH时mm分ss秒';

  /// `yyyy年MM月dd日 HH时mm分`（中文到分钟）。
  static const String ZH_Y_M_D_H_M = 'yyyy年MM月dd日 HH时mm分';

  /// `yyyy年MM月dd日`（中文仅日期）。
  static const String ZH_Y_M_D = 'yyyy年MM月dd日';

  /// `yyyy年MM月`（中文年月）。
  static const String ZH_Y_M = 'yyyy年MM月';

  /// `MM月dd日`（中文月日）。
  static const String ZH_M_D = 'MM月dd日';

  /// `MM月dd日 HH时mm分`（中文月日时分）。
  static const String ZH_M_D_H_M = 'MM月dd日 HH时mm分';

  /// `HH时mm分ss秒`（中文时分秒）。
  static const String ZH_H_M_S = 'HH时mm分ss秒';

  /// `HH时mm分`（中文时分）。
  static const String ZH_H_M = 'HH时mm分';

  /// `yyyy/MM/dd HH:mm:ss`（斜杠分隔全格式）。
  static const String PARAM_FULL = 'yyyy/MM/dd HH:mm:ss';

  /// `yyyy/MM/dd HH:mm`（斜杠分隔到分钟）。
  static const String PARAM_Y_M_D_H_M = 'yyyy/MM/dd HH:mm';

  /// `yyyy/MM/dd`（斜杠分隔日期）。
  static const String PARAM_Y_M_D = 'yyyy/MM/dd';

  /// `yyyy/MM`（斜杠分隔年月）。
  static const String PARAM_Y_M = 'yyyy/MM';

  /// `MM/dd`（斜杠分隔月日）。
  static const String PARAM_M_D = 'MM/dd';

  /// `MM/dd HH:mm`（斜杠分隔月日时分）。
  static const String PARAM_M_D_H_M = 'MM/dd HH:mm';
}

/// 各月天数（平年）。私有 const，避免被外部修改；通过 [monthDays] 只读暴露。
const Map<int, int> _monthDay = {
  1: 31,
  2: 28,
  3: 31,
  4: 30,
  5: 31,
  6: 30,
  7: 31,
  8: 31,
  9: 30,
  10: 31,
  11: 30,
  12: 31,
};

/// 月份 → 天数（平年）只读查找表。
///
/// 返回的是 `const` Map，运行时不可变（写入抛 `UnsupportedError`）。
/// 闰年二月请另行判定（见 [DateTimeUtils.isLeapYearByYear]）。
Map<int, int> get monthDays => _monthDay;
