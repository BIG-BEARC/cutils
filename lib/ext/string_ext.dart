import 'package:decimal/decimal.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:03 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///String扩展：
extension StringExt on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  double? toDouble() {
    if (isNullOrEmpty) return null;
    return double.tryParse(this!);
  }

  int? toInt() {
    if (isNullOrEmpty) return null;
    return int.tryParse(this!);
  }

  String substringSafe(int start, [int? end]) {
    if (isNullOrEmpty) return '';
    final length = this!.length;
    final safeStart = start.clamp(0, length);
    final safeEnd = end?.clamp(safeStart, length) ?? length;
    return this!.substring(safeStart, safeEnd);
  }

  int get parseIntWithDefault {
    if (isNullOrEmpty) return 0;
    final parseInt = int.tryParse(this!);
    return parseInt ?? 0;
  }

  // 空值处理
  String defaultStrWithEmpty({String? emptyStr}) {
    if (isNullOrEmpty) {
      return emptyStr ?? "--";
    }
    return this!;
  }

  String get defaultString {
    if (isNullOrEmpty) return "--";
    return this!;
  }

  String get defaultMoneyStr {
    if (isNullOrEmpty) return "0.00";
    return this!;
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
    if (isNullOrEmpty) return "--";
    final dec = Decimal.tryParse(this!);
    if (dec == null) return "--";
    return dec.shift(-2).toString();
  }

  /// 金额格式化（带单位）。
  ///
  /// 输入单位为**分（fen）**：方法将分字符串除以 100 转为元。
  /// 当 [autoMoneyUnit] 为 true 且金额 >= 10000 元（即 >= 1000000 分）时，
  /// 自动折算为「万」单位输出，例如 `12345678` 分 → `"12.35万"`。
  String moneyFormatWithUnit(bool autoMoneyUnit) {
    if (isNullOrEmpty) return "0.00";
    final money = double.tryParse(this!) ?? 0.0;

    if (autoMoneyUnit && money >= 1000000) {
      return "${(money / 1000000).toStringAsFixed(2)}万";
    }

    return (money / 100).toStringAsFixed(2);
  }

  //千分位数字字符串
  // "123456789.01".thousandSeparated → "123,456,789.01"
  String get thousandSeparated {
    if (isNullOrEmpty) return '';
    final numStr = this!;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(numStr)) return numStr;

    final parts = numStr.split('.');
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
    if (isNullOrEmpty) return this ?? '';
    final str = this!;
    if (str.length != 11) return str;
    return '${str.substring(0, 3)}****${str.substring(7)}';
  }

  //判断是否为中国大陆手机号（优化正则）
  bool get isValidChineseMobile {
    if (isNullOrEmpty) return false;
    final pattern = r'^1[3-9]\d{9}$';
    return RegExp(pattern).hasMatch(this!);
  }

  ///字符串匹配/搜索,忽略大小写
  bool containsIgnoreCase(String other) {
    if (isNullOrEmpty) return false;
    return this!.toLowerCase().contains(other.toLowerCase());
  }

  // URL 处理
  bool get isUrl {
    if (isNullOrEmpty) return false;
    final urlPattern =
        r'(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?';
    return RegExp(urlPattern).hasMatch(this!);
  }

  String removeUrlProtocol() {
    if (isNullOrEmpty) return this ?? '';
    return this!.replaceFirst(RegExp(r'https?:\/\/'), '');
  }

  // 默认非空字符串
  String get notNullStr {
    if (isNullOrEmpty) return "";
    return this!;
  }

  /// 字符串全角转半角
  String get fullToHalf {
    if (this == null || this!.isEmpty) {
      return "";
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < this!.length; i++) {
      final int code = this!.codeUnitAt(i);
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
    final s = this!;
    if (s.length != other.length) {
      throw FormatException('Strings must have the same length');
    }
    var l1 = s.runes.toList();
    var l2 = other.runes.toList();
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
    var text = this!.replaceAllMapped(RegExp('(.{$digit})'), (Match match) {
      return '${match.group(0)}$pattern';
    });
    if (text.endsWith(pattern)) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// 每隔 x 位加 pattern，从末尾开始。
  String formatDigitPatternEnd({int digit = 4, String pattern = ' '}) {
    final s = this!;
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
    return this!.replaceRange(start, end, replacement);
  }

  /// 反转字符串。
  String reverse() {
    if (isNullOrEmpty) {
      return '';
    }
    final s = this!;
    StringBuffer sb = StringBuffer();
    for (int i = s.length - 1; i >= 0; i--) {
      var codeUnitAt = s.codeUnitAt(i);
      sb.writeCharCode(codeUnitAt);
    }
    return sb.toString();
  }
}
