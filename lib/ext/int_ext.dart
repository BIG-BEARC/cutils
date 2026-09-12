import 'package:decimal/decimal.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:05 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///int 扩展
extension IntFormating on int? {
  /// 安全取值：null → `0`，否则返回自身。
  int get safeValue => this ?? 0;

  /// 安全取 double 值：null → `0.0`。
  double get safeDoubleValue => (this ?? 0).toDouble();

  /// 金额格式化处理（输入单位为**分**）。
  ///
  /// [autoMoneyUnit] 为 true 时按金额大小自动去尾零（整数无小数点、
  /// `.0`/`.x0` 去尾零），否则恒定输出两位小数。
  String currencyFormatWithDef(bool autoMoneyUnit) {
    if (this == null) {
      return autoMoneyUnit ? '0' : '0.00';
    }
    final resultAmount = this! / 100;

    if (autoMoneyUnit) {
      return _formatPrice(resultAmount);
    }
    return resultAmount.toStringAsFixed(2);
  }

  /// 内部辅助：按 [autoMoneyUnit] 去掉金额小数末尾的 0 与孤立小数点。
  String _formatPrice(double price) {
    if (price % 1 == 0) {
      // 如果价格是整数
      return price.toInt().toString();
    } else {
      // 如果价格有小数
      String priceStr = price.toString();
      final int decimalIndex = priceStr.indexOf('.');
      final String decimalPart = priceStr.substring(decimalIndex + 1);
      if (decimalPart.trim().endsWith('0')) {
        // 如果小数部分以0结尾，去掉末尾的0
        priceStr = priceStr.replaceAll(RegExp(r'0+$'), '');
        if (priceStr.endsWith('.')) {
          // 如果去掉0后只剩下小数点，也去掉小数点
          priceStr = priceStr.substring(0, priceStr.length - 1);
        }
      }
      return priceStr;
    }
  }

  /// 金额格式化处理（输入单位为**分**，恒定输出两位小数，且去掉无意义的
  /// 末尾 0：`1500` → `"15"` 而非 `"15.00"`）。null 返回 `"0.0"`。
  String get currencyFormat {
    if (this == null) {
      return '0.0';
    }
    final num = (this! / 100).toStringAsFixed(2);
    return Decimal.parse(num).toString();
  }

  /// 安全取值：null → `0`，否则返回自身（[safeValue] 的语义化别名）。
  int get defaultValue {
    if (this == null) {
      return 0;
    }
    return this!;
  }

  ///支持千分位格式化
  ///123456789.thousandSeparatedFormat → "123,456,789"
  String get thousandSeparatedFormat {
    if (this == null) return '0';
    final number = this!;
    final parts = number.toString().split('');
    final int len = parts.length;
    int pos = 0;
    String out = '';
    for (int i = len - 1; i >= 0; i--) {
      out = parts[i] + out;
      pos++;
      if (pos % 3 == 0 && i > 0) {
        out = ',$out';
      }
    }
    return out;
  }

  /// 百分比格式化方法。
  ///
  /// 将整数视为比率并乘以 100：`1.percentFormat` → `"100%"`，
  /// `25.percentFormat` → `"2500%"`。
  ///
  /// 注意：`this! * 100` 为整数运算，对于接近 `int64` 上限的输入
  /// （约 9.2e18）可能发生静默溢出。如需对极大整数做百分比格式化，
  /// 请先转 `double` 或使用 `Decimal`。
  String get percentFormat {
    if (this == null) return '0%';
    return '${this! * 100}%';
  }

  /// 通用货币格式化方法（带符号，输入单位为**分**）。
  ///
  /// example:
  /// ```dart
  /// 15000.currencyFormatWithSymbol('¥');                     // ¥150.00
  /// 15000.currencyFormatWithSymbol('\$', autoMoneyUnit: true); // \$150.00
  /// ```
  String currencyFormatWithSymbol(String symbol, {bool autoMoneyUnit = false}) {
    if (this == null) {
      return '${symbol}0.00';
    }
    final resultAmount = this! / 100;

    String formatted;
    if (autoMoneyUnit) {
      formatted = _formatPrice(resultAmount);
    } else {
      formatted = resultAmount.toStringAsFixed(2);
    }

    // 中文（及通用货币）惯例：符号与数字之间不加空格（¥150 而非 ¥ 150）。
    return '$symbol$formatted';
  }

  /// 单位自动转换（万 / 亿）。null 返回 `'0'`。
  ///
  /// example:
  /// ```dart
  /// 123456789.autoUnitFormat; // "1.23亿"
  /// 15000.autoUnitFormat;     // "1.50万"
  /// ```
  String get autoUnitFormat {
    final self = this;
    if (self == null) return '0';

    final value = self.toDouble();
    if (value >= 1e8) {
      return '${(value / 1e8).toStringAsFixed(2)}亿';
    } else if (value >= 1e4) {
      return '${(value / 1e4).toStringAsFixed(2)}万';
    } else {
      return value.toInt().toString();
    }
  }
}
