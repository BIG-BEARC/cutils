// Package imports:
import 'package:decimal/decimal.dart';

// Project imports:
import 'string_ext.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:04 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///double 扩展
extension DoubleFormating on double? {
  /// 空值判断：是否为 null（注意 `0.0` 不算空）。
  bool get isNullOrEmpty => this == null;

  /// 安全取值：null → `0.0`。
  double get safeValue => this ?? 0.0;

  /// 默认值格式化（[safeValue] 的语义化别名）。
  double get defaultValue => safeValue;

  /// 分转元并格式化（输入单位为**分**，恒定输出两位小数）。
  String get currencyFormat {
    return (safeValue / 100).toStringAsFixed(2);
  }

  /// 带单位格式化（输入单位为**分**）。
  ///
  /// [autoMoneyUnit] 为 true 且金额 >= 10000 元（即 >= 1000000 分）时，
  /// 自动折算为「万」单位输出；否则除以 100 输出两位小数元。
  ///
  /// 走 [Decimal] 运算（与 `StringExt.moneyFormatWithUnit` 同策略），避免
  /// 大额输入时 double 精度丢失；[Decimal] 无法解析的异形值（如科学计数法
  /// 极大 double）回退旧 double 路径保持行为不变。
  String moneyFormatWithUnit(bool autoMoneyUnit) {
    final value = this;
    if (value == null) return '0.00';

    final dec = Decimal.tryParse(value.toString());
    if (dec != null) {
      if (autoMoneyUnit && dec >= Decimal.fromInt(1000000)) {
        return '${dec.shift(-6).toStringAsFixed(2)}万';
      }
      return dec.shift(-2).toStringAsFixed(2);
    }

    // 回退：异形值走旧 double 路径。
    if (autoMoneyUnit && value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}万';
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
    final String integerPart = parts[0];
    final String decimalPart = '.${parts[1]}';

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

  /// 数值比较：是否为正数（`> 0`）。
  bool get isPositive => safeValue > 0;

  /// 数值比较：是否为负数（`< 0`）。
  bool get isNegative => safeValue < 0;

  /// 数值比较：是否为零（`== 0`）。
  bool get isZero => safeValue == 0;

  /// 数学运算：相加（普通浮点运算，有精度风险；如需精确请用 [NumUtils.addNum]）。
  double add(double other) => safeValue + other;

  /// 数学运算：相减（普通浮点运算；如需精确请用 [NumUtils.subtractNum]）。
  double subtract(double other) => safeValue - other;

  /// 数学运算：相乘（普通浮点运算；如需精确请用 [NumUtils.multiplyNum]）。
  double multiplyBy(double factor) => safeValue * factor;

  /// 数学运算：相除。除数为 0 时返回 `0.0`（不抛异常）；如需精确或显式报错请用
  /// [NumUtils.divideNum]。
  double divideBy(double divisor) {
    if (divisor == 0) return 0.0;
    return safeValue / divisor;
  }

  /// 百分比格式化。
  ///
  /// 将 [this] 视为比率（0.25 表示 25%）并乘以 100，与
  /// [IntFormating.percentFormat] 语义一致。
  ///
  /// 输出会去掉小数末尾的 0 及可能的小数点，因此整百分数显示为
  /// `"25%"` 而非 `"25.00%"`；[fractionDigits] 仅控制最大小数位数
  /// （先四舍五入再去尾零）。
  ///
  /// BREAKING: 历史实现不乘以 100（`0.25.percentFormat()` 返回
  /// `"0.25%"`），现已统一为乘以 100。
  String percentFormat([int fractionDigits = 2]) {
    var s = (safeValue * 100).toStringAsFixed(fractionDigits);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return '$s%';
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
    // 科学计数法等无小数点形态（如 1e21.toString() → "1e+21"），千分位格式化无意义，原样返回
    if (!s.contains('.')) return s;
    final list = s.split('.');
    final left = list[0].formatDigitPatternEnd(digit: digit, pattern: pattern);
    final right = list[1];
    return '$left.$right';
  }
}
