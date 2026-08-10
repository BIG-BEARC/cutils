import 'string_ext.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:04 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///double 扩展
extension DoubleFormating on double? {
  // 空值判断
  bool get isNullOrEmpty => this == null;

  // 安全取值
  double get safeValue => this ?? 0.0;

  // 默认值格式化
  double get defaultValue => safeValue;

  // 分转元并格式化
  String get currencyFormat {
    return (safeValue / 100).toStringAsFixed(2);
  }

  // 带单位格式化（支持外部控制是否启用单位）
  String moneyFormatWithUnit(bool autoMoneyUnit) {
    if (isNullOrEmpty) return "0.00";
    final value = this!;

    if (autoMoneyUnit && value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(2)}万";
    }

    return (value / 100).toStringAsFixed(2);
  }

  // 千分位格式化
  //
  // The sign is stripped first and the magnitude is formatted, then `-`
  // is prepended for negatives. Otherwise the leading `-` is treated as
  // a digit group and yields output like `-,123.00`.
  String get thousandSeparated {
    final value = safeValue;
    final isNegative = value.isNegative;
    final magnitude = isNegative ? -value : value;
    final numStr = magnitude.toStringAsFixed(2);
    final parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = '.${parts[1]}';

    var result = '';
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        result += ',';
      }
      result += integerPart[i];
    }

    final sign = isNegative ? '-' : '';
    return '$sign$result$decimalPart';
  }

  // 数值比较
  bool get isPositive => safeValue > 0;
  bool get isNegative => safeValue < 0;
  bool get isZero => safeValue == 0;

  // 数学运算
  double add(double other) => safeValue + other;
  double subtract(double other) => safeValue - other;
  double multiplyBy(double factor) => safeValue * factor;
  double divideBy(double divisor) {
    if (divisor == 0) return 0.0;
    return safeValue / divisor;
  }

  // 百分比格式化
  String percentFormat([int fractionDigits = 2]) {
    return '${safeValue.toStringAsFixed(fractionDigits)}%';
  }

  /// 千分位格式化（保留原始小数位）。
  ///
  /// 将整数部分每 [digit] 位用 [pattern] 分组，小数部分原样保留。
  /// 与 [thousandSeparated] 不同：不强制两位小数，且支持自定义分组。
  /// 例如：`1234567.89.formatDoubleComma3()` → `"1,234,567.89"`。
  String formatDoubleComma3({int digit = 3, String pattern = ','}) {
    final n = this;
    if (n == null) return '0.0';
    final s = n.toString();
    final list = s.split('.');
    final left = list[0].formatDigitPatternEnd(digit: digit, pattern: pattern);
    final right = list[1];
    return '$left.$right';
  }
}
