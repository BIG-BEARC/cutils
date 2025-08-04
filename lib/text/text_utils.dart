/// * @Author: chuxiong
/// * @Created at: 23-07-2025 16:38
/// * @Email:
/// * description 文本工具类
final textUtils = TextUtils();

class TextUtils {
  TextUtils._();

  static final _instance = TextUtils._();

  factory TextUtils() => _instance;

  /// 判断文本内容是否为空
  bool isEmpty(String? text) {
    return text == null || text.isEmpty;
  }

  /// 判断文本内容是否不为空
  bool isNotEmpty(String? text) {
    return !isEmpty(text);
  }

  /// 判断字符串是以xx开头
  bool startsWith(String? str, Pattern prefix, [int index = 0]) {
    if (str == null) return false;
    return str.startsWith(prefix, index);
  }

  /// 判断一个字符串以任何给定的前缀开始
  bool startsWithAny(
    String? str,
    List<Pattern> prefixes, [
    int index = 0,
  ]) {
    if (str == null) return false;
    return prefixes.any((prefix) => str.startsWith(prefix, index));
  }

  /// 判断字符串中是否包含xx
  bool contains(String? str, Pattern searchPattern, [int startIndex = 0]) {
    if (str == null) return false;
    return str.contains(searchPattern, startIndex);
  }

  /// 判断一个字符串是否包含任何给定的搜索模式
  bool containsAny(
    String? str,
    List<Pattern> searchPatterns, [
    int startIndex = 0,
  ]) {
    if (str == null) return false;
    return searchPatterns.any((prefix) => str.contains(prefix, startIndex));
  }

  /// 使用点缩写字符串
  String? abbreviate(String? str, int maxWidth, {int offset = 0}) {
    if (str == null) {
      return null;
    } else if (str.length <= maxWidth) {
      return str;
    } else if (offset < 3) {
      return '${str.substring(offset, (offset + maxWidth) - 3)}...';
    } else if (maxWidth - offset < 3) {
      return '...${str.substring(offset, (offset + maxWidth) - 3)}';
    }
    return '...${str.substring(offset, (offset + maxWidth) - 6)}...';
  }

  /// 比较两个字符串是否相同
  int compare(String? str1, String? str2) {
    if (str1 == null || str2 == null) {
      return str1 == null ? -1 : 1;
    }

    if (str1 == str2) {
      return 0;
    }

    return str1.compareTo(str2);
  }

  /// 比较两个长度一样的字符串有几个字符不同
  int hammingDistance(String str1, String str2) {
    if (str1.length != str2.length) {
      throw FormatException('Strings must have the same length');
    }
    var l1 = str1.runes.toList();
    var l2 = str2.runes.toList();
    var distance = 0;
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) {
        distance++;
      }
    }
    return distance;
  }

  /// 每隔 x位 加 pattern。比如用来格式化银行卡
  String formatDigitPattern(String text, {int digit = 4, String pattern = ' '}) {
    text = text.replaceAllMapped(RegExp('(.{$digit})'), (Match match) {
      return '${match.group(0)}$pattern';
    });
    if (text.endsWith(pattern)) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// 每隔 x位 加 pattern, 从末尾开始
  String formatDigitPatternEnd(String text, {int digit = 4, String pattern = ' '}) {
    String temp = reverse(text);
    temp = formatDigitPattern(temp, digit: digit, pattern: pattern);
    temp = reverse(temp);
    return temp;
  }

  /// 每隔4位加空格
  String formatSpace4(String text) {
    return formatDigitPattern(text);
  }

  /// 每隔3三位加逗号
  /// num 数字或数字字符串。int型。
  String formatComma3(Object num) {
    return formatDigitPatternEnd(num.toString(), digit: 3, pattern: ',');
  }

  /// 每隔3三位加逗号
  /// num 数字或数字字符串。double型。
  String formatDoubleComma3(Object num, {int digit = 3, String pattern = ','}) {
    List<String> list = num.toString().split('.');
    String left = formatDigitPatternEnd(list[0], digit: digit, pattern: pattern);
    String right = list[1];
    return '$left.$right';
  }

  /// 隐藏手机号中间n位
  String hideNumber(String phoneNo, {int start = 3, int end = 7, String replacement = '****'}) {
    return phoneNo.replaceRange(start, end, replacement);
  }

  /// 替换字符串中的数据
  String replace(String text, Pattern from, String replace) {
    return text.replaceAll(from, replace);
  }

  /// 按照正则切割字符串
  List<String> split(String text, Pattern pattern) {
    return text.split(pattern);
  }

  /// 反转字符串
  String reverse(String text) {
    if (isEmpty(text)) {
      return '';
    }
    StringBuffer sb = StringBuffer();
    for (int i = text.length - 1; i >= 0; i--) {
      var codeUnitAt = text.codeUnitAt(i);
      sb.writeCharCode(codeUnitAt);
    }
    return sb.toString();
  }

  String currencyFormat(int? money) {
    if (money == null) {
      return "";
    }
    String moneyStr = money.toString();
    String finalStr = "";
    int groupSize = 3;
    int oddNumberLength = moneyStr.length - (moneyStr.length ~/ groupSize) * groupSize;
    if (oddNumberLength > 0) {
      finalStr += moneyStr.substring(0, oddNumberLength);
      if (moneyStr.length > groupSize) {
        finalStr += ",";
      }
    }
    for (int i = oddNumberLength; i < moneyStr.length; i += groupSize) {
      finalStr += moneyStr.substring(i, i + groupSize);
      if (i + groupSize < moneyStr.length - 1) {
        finalStr += ",";
      }
    }
    return finalStr;
  }
}
