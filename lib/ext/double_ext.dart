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
  String get thousandSeparated {
    final value = safeValue;
    final numStr = value.toStringAsFixed(2);
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

    return '$result$decimalPart';
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
}
