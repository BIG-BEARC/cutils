import 'package:decimal/decimal.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:03 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///String扩展：
extension StringExt on String? {
  bool get isNullOrEmpty => this == null || (this?.isEmpty ?? true);

  double? toDouble() {
    final s = this;
    if (s == null) return null;
    return double.tryParse(s);
  }

  int? toInt() {
    final s = this;
    if (s == null) return null;
    return int.tryParse(s);
  }

  String substringSafe(int start, [int? end]) {
    final s = this;
    if (s == null || s.isEmpty) return '';
    final length = s.length;
    final safeStart = start.clamp(0, length);
    final safeEnd = end?.clamp(safeStart, length) ?? length;
    return s.substring(safeStart, safeEnd);
  }

  int get parseIntWithDefault {
    final s = this;
    if (s == null) return 0;
    final parseInt = int.tryParse(s);
    return parseInt ?? 0;
  }

  // 空值处理
  String defaultStrWithEmpty({String? emptyStr}) {
    final s = this;
    if (s == null || s.isEmpty) {
      return emptyStr ?? "--";
    }
    return s;
  }

  String get defaultString {
    final s = this;
    if (s == null || s.isEmpty) return "--";
    return s;
  }

  String get defaultMoneyStr {
    final s = this;
    if (s == null || s.isEmpty) return "0.00";
    return s;
  }

  /// 金额格式化。
  ///
  /// 将表示分（fen）的数字字符串除以 100 转为元，并返回十进制字符串。
  /// 使用 [Decimal] 直接运算，避免浮点除法在 2^53 边界附近丢精度，
  /// 以及 `double.toString()` 在极大值时输出科学计数法。
  ///
  /// 注意：整元结果不再追加 `.0`（例如 `"100".formatMoney` → `"1"`，
  /// 而非旧行为的 `"1.0"`），因为 [Decimal] 不会合成不存在的小数位。
  /// 非整元结果与旧实现一致。
  String get formatMoney {
    final s = this;
    if (s == null || s.isEmpty) return "--";
    final dec = Decimal.tryParse(s);
    if (dec == null) return "--";
    return dec.shift(-2).toString();
  }

  /// 金额格式化（带单位）。
  ///
  /// 输入单位为**分（fen）**：方法将分字符串除以 100 转为元。
  /// 当 [autoMoneyUnit] 为 true 且金额 >= 10000 元（即 >= 1000000 分）时，
  /// 自动折算为「万」单位输出，例如 `12345678` 分 → `"12.35万"`。
  String moneyFormatWithUnit(bool autoMoneyUnit) {
    final s = this;
    if (s == null || s.isEmpty) return "0.00";
    final money = double.tryParse(s) ?? 0.0;

    if (autoMoneyUnit && money >= 1000000) {
      return "${(money / 1000000).toStringAsFixed(2)}万";
    }

    return (money / 100).toStringAsFixed(2);
  }

  //千分位数字字符串
  // "123456789.01".thousandSeparated → "123,456,789.01"
  String get thousandSeparated {
    final s = this;
    if (s == null || s.isEmpty) return '';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return s;

    final parts = s.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    var result = '';
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        result += ',';
      }
      result += integerPart[i];
    }

    return result + decimalPart;
  }

  //星号脱敏中间四位
  //"13812345678".maskMobile → "138****5678"
  String get maskMobile {
    final str = this;
    if (str == null || str.isEmpty) return '';
    if (str.length != 11) return str;
    return '${str.substring(0, 3)}****${str.substring(7)}';
  }

  //判断是否为中国大陆手机号（优化正则）
  bool get isValidChineseMobile {
    final s = this;
    if (s == null || s.isEmpty) return false;
    final pattern = r'^1[3-9]\d{9}$';
    return RegExp(pattern).hasMatch(s);
  }

  ///字符串匹配/搜索,忽略大小写
  bool containsIgnoreCase(String other) {
    final s = this;
    if (s == null || s.isEmpty) return false;
    return s.toLowerCase().contains(other.toLowerCase());
  }

  // URL 处理
  bool get isUrl {
    final s = this;
    if (s == null || s.isEmpty) return false;
    final urlPattern =
        r'(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?';
    return RegExp(urlPattern).hasMatch(s);
  }

  String removeUrlProtocol() {
    final s = this;
    if (s == null || s.isEmpty) return s ?? '';
    return s.replaceFirst(RegExp(r'https?:\/\/'), '');
  }

  // 默认非空字符串
  String get notNullStr {
    final s = this;
    if (s == null || s.isEmpty) return "";
    return s;
  }

  /// 字符串全角转半角
  String get fullToHalf {
    final s = this;
    if (s == null || s.isEmpty) {
      return "";
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int code = s.codeUnitAt(i);
      // 全角空格转换为半角空格
      if (code == 12288) {
        buffer.writeCharCode(32);
      }
      // 全角字符范围：65281 到 65374
      else if (code >= 65281 && code <= 65374) {
        buffer.writeCharCode(code - 65248);
      }
      // 其他字符保持不变
      else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// 判断一个字符串以任何给定的前缀开始。
  bool startsWithAny(List<Pattern> prefixes, [int index = 0]) {
    final s = this;
    if (s == null) return false;
    return prefixes.any((prefix) => s.startsWith(prefix, index));
  }

  /// 判断一个字符串是否包含任何给定的搜索模式。
  bool containsAny(List<Pattern> searchPatterns, [int startIndex = 0]) {
    final s = this;
    if (s == null) return false;
    return searchPatterns.any((prefix) => s.contains(prefix, startIndex));
  }

  /// 使用点缩写字符串。
  String? abbreviate(int maxWidth, {int offset = 0}) {
    final s = this;
    if (s == null) {
      return null;
    } else if (s.length <= maxWidth) {
      return s;
    } else if (offset < 3) {
      return '${s.substring(offset, (offset + maxWidth) - 3)}...';
    } else if (maxWidth - offset < 3) {
      return '...${s.substring(offset, (offset + maxWidth) - 3)}';
    }
    return '...${s.substring(offset, (offset + maxWidth) - 6)}...';
  }

  /// 比较两个字符串是否相同，返回 -1/0/1。
  int compare(String? other) {
    final s = this;
    if (s == null || other == null) {
      return s == null ? -1 : 1;
    }
    if (s == other) {
      return 0;
    }
    return s.compareTo(other);
  }

  /// 比较两个长度一样的字符串有几个字符不同。
  int hammingDistance(String other) {
    final s = this;
    if (s == null || s.length != other.length) {
      throw FormatException('Strings must have the same length');
    }
    final l1 = s.runes.toList();
    final l2 = other.runes.toList();
    var distance = 0;
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) {
        distance++;
      }
    }
    return distance;
  }

  /// 每隔 x 位加 pattern。比如用来格式化银行卡。
  String formatDigitPattern({int digit = 4, String pattern = ' '}) {
    final s = this;
    if (s == null) return '';
    var text = s.replaceAllMapped(RegExp('(.{$digit})'), (Match match) {
      return '${match.group(0)}$pattern';
    });
    if (text.endsWith(pattern)) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// 每隔 x 位加 pattern，从末尾开始。
  String formatDigitPatternEnd({int digit = 4, String pattern = ' '}) {
    final s = this;
    if (s == null) return '';
    String temp = s.reverse();
    temp = temp.formatDigitPattern(digit: digit, pattern: pattern);
    temp = temp.reverse();
    return temp;
  }

  /// 每隔 4 位加空格。
  String formatSpace4() {
    return formatDigitPattern();
  }

  /// 隐藏手机号中间 n 位。
  String hideNumber({int start = 3, int end = 7, String replacement = '****'}) {
    final s = this;
    if (s == null) return '';
    return s.replaceRange(start, end, replacement);
  }

  /// 反转字符串。
  String reverse() {
    final s = this;
    if (s == null || s.isEmpty) {
      return '';
    }
    final sb = StringBuffer();
    for (int i = s.length - 1; i >= 0; i--) {
      final codeUnitAt = s.codeUnitAt(i);
      sb.writeCharCode(codeUnitAt);
    }
    return sb.toString();
  }
}
