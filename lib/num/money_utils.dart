import 'package:decimal/decimal.dart';

import 'money_unit.dart';

/// * @Author: chuxiong
/// * @Created at: 23-07-2025 17:29
/// * @Email:
/// * description
/// 金额格式化工具（输入金额一律以**分（fen）**为单位）。
class MoneyUtils {
  MoneyUtils._();

  static final _ins = MoneyUtils._();

  factory MoneyUtils() => _ins;

  /// 人民币符号。
  static const String YUAN = '¥';

  /// 中文「元」。
  static const String YUAN_ZH = '元';

  /// 美元符号。
  static const String DOLLAR = '\$';

  /// fen to yuan, format output.
  /// 分 转 元, format格式输出.
  ///
  /// Formats directly from a [Decimal] (fen → `shift(-2)`) rather than
  /// going through `double`, so a fen amount near the 2^53 boundary
  /// (e.g. `9007199254740993`) preserves its exact integer precision
  /// instead of being corrupted by the double round-trip.
  String changeF2Y(int amount, {MoneyFormat format = MoneyFormat.NORMAL}) {
    final yuanDecimal = Decimal.fromInt(amount).shift(-2);
    switch (format) {
      case MoneyFormat.NORMAL:
        return yuanDecimal.toStringAsFixed(2);
      case MoneyFormat.END_INTEGER:
        if (amount % 100 == 0) {
          return yuanDecimal.truncate().toString();
        } else if (amount % 10 == 0) {
          return yuanDecimal.toStringAsFixed(1);
        } else {
          return yuanDecimal.toStringAsFixed(2);
        }
      case MoneyFormat.YUAN_INTEGER:
        return (amount % 100 == 0)
            ? yuanDecimal.truncate().toString()
            : yuanDecimal.toStringAsFixed(2);
    }
  }

  /// fen str to yuan, format & unit  output.
  /// 分字符串 转 元, format 与 unit 格式 输出.
  ///
  /// Throws [ArgumentError] (rather than a bare [FormatException]) when
  /// [amountStr] is empty, non-numeric, or overflows `int`.
  String changeFStr2YWithUnit(String amountStr,
      {MoneyFormat format = MoneyFormat.NORMAL,
      MoneyUnit unit = MoneyUnit.NORMAL}) {
    final amount = int.tryParse(amountStr);
    if (amount == null) {
      throw ArgumentError(
        'changeFStr2YWithUnit: amountStr must be a valid integer fen '
        'value (got: "$amountStr")',
      );
    }
    return changeF2YWithUnit(amount, format: format, unit: unit);
  }

  /// fen to yuan, format & unit  output.
  /// 分 转 元, format 与 unit 格式 输出.
  String changeF2YWithUnit(int amount,
      {MoneyFormat format = MoneyFormat.NORMAL,
      MoneyUnit unit = MoneyUnit.NORMAL}) {
    return withUnit(changeF2Y(amount, format: format), unit);
  }

  /// with unit.
  /// 拼接单位.
  ///
  /// Exhaustive switch expression over [MoneyUnit] — adding a new enum
  /// value will produce a compile-time error here instead of silently
  /// falling through.
  String withUnit(String moneyTxt, MoneyUnit unit) {
    return switch (unit) {
      MoneyUnit.NORMAL => moneyTxt,
      MoneyUnit.YUAN => YUAN + moneyTxt,
      MoneyUnit.YUAN_ZH => moneyTxt + YUAN_ZH,
      MoneyUnit.DOLLAR => DOLLAR + moneyTxt,
    };
  }
}
