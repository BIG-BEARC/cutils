import 'package:decimal/decimal.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:03 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///String扩展：覆盖空值判定、数值解析、金额/千分位/手机号脱敏、URL 处理、全半角等。
extension StringExt on String? {
  /// 是否为 null 或空字符串。
  bool get isNullOrEmpty => this == null || (this?.isEmpty ?? true);

  /// 尝试解析为 double；非数字或 null 返回 null。
  double? toDouble() {
    final s = this;
    if (s == null) return null;
    return double.tryParse(s);
  }

  /// 尝试解析为 int；非整数或 null 返回 null。
  int? toInt() {
    final s = this;
    if (s == null) return null;
    return int.tryParse(s);
  }

  /// 越界安全的 [substring]：[start]/[end] 自动夹到 `[0, length]`；
  /// null / 空串返回 `''`。
  String substringSafe(int start, [int? end]) {
    final s = this;
    if (s == null || s.isEmpty) return '';
    final length = s.length;
    final safeStart = start.clamp(0, length);
    final safeEnd = end?.clamp(safeStart, length) ?? length;
    return s.substring(safeStart, safeEnd);
  }

  /// 解析为 int，失败或 null 返回 `0`。
  int get parseIntWithDefault {
    final s = this;
    if (s == null) return 0;
    final parseInt = int.tryParse(s);
    return parseInt ?? 0;
  }

  /// 空值处理：null / 空串返回 [emptyStr]（默认 `"--"`）。
  String defaultStrWithEmpty({String? emptyStr}) {
    final s = this;
    if (s == null || s.isEmpty) {
      return emptyStr ?? '--';
    }
    return s;
  }

  /// 空值处理：null / 空串返回 `"--"`。
  String get defaultString {
    final s = this;
    if (s == null || s.isEmpty) return '--';
    return s;
  }

  /// 空值处理：null / 空串返回 `"0.00"`（金额占位）。
  String get defaultMoneyStr {
    final s = this;
    if (s == null || s.isEmpty) return '0.00';
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
    if (s == null || s.isEmpty) return '--';
    final dec = Decimal.tryParse(s);
    if (dec == null) return '--';
    return dec.shift(-2).toString();
  }

  /// 金额格式化（带单位）。
  ///
  /// 输入单位为**分（fen）**：方法将分字符串除以 100 转为元。
  /// 当 [autoMoneyUnit] 为 true 且金额 >= 10000 元（即 >= 1000000 分）时，
  /// 自动折算为「万」单位输出，例如 `12345678` 分 → `"12.35万"`。
  ///
  /// 走 [Decimal] 运算（与 [formatMoney] 同策略），避免大额输入时
  /// double 精度丢失；[Decimal] 无法解析的异形输入（如科学计数法）
  /// 回退旧 double 路径保持行为不变。
  String moneyFormatWithUnit(bool autoMoneyUnit) {
    final s = this;
    if (s == null || s.isEmpty) return '0.00';
    final dec = Decimal.tryParse(s);

    if (dec != null) {
      if (autoMoneyUnit && dec >= Decimal.fromInt(1000000)) {
        return '${dec.shift(-6).toStringAsFixed(2)}万';
      }
      return dec.shift(-2).toStringAsFixed(2);
    }

    // 回退：异形输入走旧 double 路径（失败按 0.00 处理）。
    final money = double.tryParse(s) ?? 0.0;
    if (autoMoneyUnit && money >= 1000000) {
      return '${(money / 1000000).toStringAsFixed(2)}万';
    }
    return (money / 100).toStringAsFixed(2);
  }

  /// 千分位数字字符串（仅接受 `^\d+(\.\d+)?$`，否则原样返回）。
  ///
  /// example:
  /// ```dart
  /// "123456789.01".thousandSeparated; // "123,456,789.01"
  /// ```
  String get thousandSeparated {
    final s = this;
    if (s == null || s.isEmpty) return '';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return s;

    final parts = s.split('.');
    final String integerPart = parts[0];
    final String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    var result = '';
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        result += ',';
      }
      result += integerPart[i];
    }

    return result + decimalPart;
  }

  /// 星号脱敏手机号中间四位：仅对 11 位字符串生效，其它原样返回。
  ///
  /// example: `"13812345678".maskMobile` → `"138****5678"`。
  String get maskMobile {
    final str = this;
    if (str == null || str.isEmpty) return '';
    if (str.length != 11) return str;
    return '${str.substring(0, 3)}****${str.substring(7)}';
  }

  /// 是否为中国大陆手机号（正则 `^1[3-9]\d{9}$`）。
  bool get isValidChineseMobile {
    final s = this;
    if (s == null || s.isEmpty) return false;
    const pattern = r'^1[3-9]\d{9}$';
    return RegExp(pattern).hasMatch(s);
  }

  ///字符串匹配/搜索,忽略大小写
  bool containsIgnoreCase(String other) {
    final s = this;
    if (s == null || s.isEmpty) return false;
    return s.toLowerCase().contains(other.toLowerCase());
  }

  /// 是否为合法 URL（粗匹配）。
  bool get isUrl {
    final s = this;
    if (s == null || s.isEmpty) return false;
    const urlPattern =
        r'(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?';
    return RegExp(urlPattern).hasMatch(s);
  }

  /// 移除 URL 协议（`http://` / `https://`）。null / 空串返回 `''`。
  String removeUrlProtocol() {
    final s = this;
    if (s == null || s.isEmpty) return s ?? '';
    return s.replaceFirst(RegExp(r'https?:\/\/'), '');
  }

  /// 返回非空字符串：null / 空串转换为 `""`。
  String get notNullStr {
    final s = this;
    if (s == null || s.isEmpty) return '';
    return s;
  }

  /// 字符串全角转半角
  String get fullToHalf {
    final s = this;
    if (s == null || s.isEmpty) {
      return '';
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
    }
    // 对齐 Apache Commons StringUtils.abbreviate 的前置校验
    if (maxWidth < 4) {
      throw ArgumentError.value(maxWidth, 'maxWidth', '必须 >= 4');
    }
    if (offset < 0 || offset > s.length) {
      throw ArgumentError.value(offset, 'offset', '必须在 [0, length] 内');
    }
    if (s.length <= maxWidth) {
      return s;
    }
    // 统一钳制右边界，杜绝负数或越界 end 导致的 RangeError
    final end = (offset + maxWidth - 3).clamp(0, s.length);
    if (offset < 3) {
      return '${s.substring(offset, end)}...';
    } else if (maxWidth - offset < 3) {
      return '...${s.substring(offset, end)}';
    }
    return '...${s.substring(offset, (offset + maxWidth - 6).clamp(offset, s.length))}...';
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
      throw const FormatException('Strings must have the same length');
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
