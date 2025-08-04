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

  // 金额格式化
  String get formatMoney {
    if (isNullOrEmpty) return "--";
    final money = double.tryParse(this!);
    if (money == null) return "--";
    return (money / 100).toString();
  }

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
    final urlPattern = r'(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?';
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
}
