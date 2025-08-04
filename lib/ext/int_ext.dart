import 'package:decimal/decimal.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:05 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///int 扩展
extension IntFormating on int? {
  // 安全取值
  int get safeValue => this ?? 0;
  double get safeDoubleValue => (this ?? 0).toDouble();

  //分格式化处理
  String currencyFormatWithDef(bool autoMoneyUnit) {
    if (this == null) {
      return autoMoneyUnit ? "0" : "0.00";
    }
    final resultAmount = this! / 100;

    if (autoMoneyUnit) {
      return _formatPrice(resultAmount);
    }
    return resultAmount.toStringAsFixed(2);
  }

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

  //分格式化处理
  String get currencyFormat {
    if (this == null) {
      return "0.0";
    }
    final num = (this! / 100).toStringAsFixed(2);
    return Decimal.parse(num).toString();
  }

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
    int len = parts.length;
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

  ///百分比格式化方法
  ///0.25.percentFormat → "25%"
  String get percentFormat {
    if (this == null) return '0%';
    return '${this! * 100}%';
  }

  ///通用货币格式化方法（带符号）
  ///print(15000.currencyFormatWithSymbol("¥")); // ¥ 150
  // print(15000.currencyFormatWithSymbol("$", autoMoneyUnit: true)); // $ 150.00
  String currencyFormatWithSymbol(String symbol, {bool autoMoneyUnit = false}) {
    if (this == null) {
      return '$symbol 0.00';
    }
    final resultAmount = this! / 100;

    String formatted;
    if (autoMoneyUnit) {
      formatted = _formatPrice(resultAmount);
    } else {
      formatted = resultAmount.toStringAsFixed(2);
    }

    return '$symbol $formatted';
  }

  //单位自动转换（万、亿等）
  // 123456789.autoUnitFormat → "1.23亿"
  // 15000.autoUnitFormat → "1.50万"
  String get autoUnitFormat {
    if (this == null) return '0';

    final value = this!.toDouble();
    if (value >= 1e8) {
      return '${(value / 1e8).toStringAsFixed(2)}亿';
    } else if (value >= 1e4) {
      return '${(value / 1e4).toStringAsFixed(2)}万';
    } else {
      return value.toInt().toString();
    }
  }
}
