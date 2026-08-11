import 'dart:convert';

import 'regex_constants.dart';

/// 正则表达式工具类
/// 提供各种正则表达式验证和处理功能
/// * @Author: chuxiong
/// * @Created at: 30-07-2025 18:28
/// * @Email:
/// * description 提供正则表达式相关的工具方法
class RegexUtils {
  RegexUtils._();

  /// 身份证前两位省份代码字典（懒加载，供 [isIDCard18Exact] 校验使用）。
  /// 改为静态后所有调用共享同一份缓存，行为与原单例一致。
  static final Map<String, String> cityMap = {};

  /// Return whether input matches regex of simple mobile.
  /// 判断输入字符串是否符合手机号
  static bool isMobileSimple(String input) {
    return matches(RegexConstants.REGEX_MOBILE_SIMPLE, input);
  }

  /// Return whether input matches regex of exact mobile.
  /// 精确验证是否是手机号
  static bool isMobileExact(String input) {
    return matches(RegexConstants.REGEX_MOBILE_EXACT, input);
  }

  /// Return whether input matches regex of telephone number.
  /// 判断返回输入是否匹配电话号码的正则表达式
  static bool isTel(String input) {
    return matches(RegexConstants.REGEX_TEL, input);
  }

  /// Return whether input matches regex of id card number.
  /// 返回输入是否匹配身份证号码的正则表达式。
  static bool isIDCard(String input) {
    if (input.length == 15) {
      return isIDCard15(input);
    }
    if (input.length == 18) {
      return isIDCard18Exact(input);
    }
    return false;
  }

  /// Return whether input matches regex of id card number which length is 15.
  /// 返回输入是否匹配长度为15的身份证号码的正则表达式。
  static bool isIDCard15(String input) {
    return matches(RegexConstants.REGEX_ID_CARD15, input);
  }

  /// Return whether input matches regex of id card number which length is 18.
  /// 返回输入是否匹配长度为18的身份证号码的正则表达式。
  static bool isIDCard18(String input) {
    return matches(RegexConstants.REGEX_ID_CARD18, input);
  }

  /// Return whether input matches regex of exact id card number which length is 18.
  /// 返回输入是否匹配长度为18的id卡号的正则表达式。
  static bool isIDCard18Exact(String input) {
    if (isIDCard18(input)) {
      List<int> factor = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
      List<String> suffix = [
        '1',
        '0',
        'X',
        '9',
        '8',
        '7',
        '6',
        '5',
        '4',
        '3',
        '2'
      ];
      if (cityMap.isEmpty) {
        List<String> list = ID_CARD_PROVINCE_DICT;
        List<MapEntry<String, String>> mapEntryList = [];
        for (int i = 0, length = list.length; i < length; i++) {
          List<String> tokens = list[i].trim().split('=');
          MapEntry<String, String> mapEntry = MapEntry(tokens[0], tokens[1]);
          mapEntryList.add(mapEntry);
        }
        cityMap.addEntries(mapEntryList);
      }
      if (cityMap[input.substring(0, 2)] != null) {
        int weightSum = 0;
        for (int i = 0; i < 17; ++i) {
          weightSum += (input.codeUnitAt(i) - '0'.codeUnitAt(0)) * factor[i];
        }
        int idCardMod = weightSum % 11;
        // [REGEX_ID_CARD18] allows a case-insensitive trailing `X`; normalize
        // it before comparing against the uppercase suffix table.
        final String idCardLast =
            String.fromCharCode(input.codeUnitAt(17)).toUpperCase();
        return idCardLast == suffix[idCardMod];
      }
    }
    return false;
  }

  /// Return whether input matches regex of email.
  ///
  /// Uses the non-backtracking [RegexConstants.REGEX_EMAIL] pattern and caps
  /// the input at 254 characters per RFC 5321 to bound the work for
  /// pathological inputs. The pattern is intentionally permissive about the
  /// local part (any non-space, non-`@` character is allowed).
  static bool isEmail(String input) {
    if (input.length > 254) return false;
    return matches(RegexConstants.REGEX_EMAIL, input);
  }

  /// Return whether input matches regex of url.
  /// 返回输入是否匹配url的正则表达式。
  static bool isURL(String input) {
    return matches(RegexConstants.REGEX_URL, input);
  }

  /// Return whether input matches regex of Chinese character.
  /// 返回输入是否匹配汉字的正则表达式。
  static bool isZh(String input) {
    return '〇' == input || matches(RegexConstants.REGEX_ZH, input);
  }

  /// Return whether input matches regex of date which pattern is 'yyyy-MM-dd'.
  /// 返回输入是否匹配样式为'yyyy-MM-dd'的日期的正则表达式。
  static bool isDate(String input) {
    return matches(RegexConstants.REGEX_DATE, input);
  }

  /// Return whether input matches regex of ip address.
  /// 返回输入是否匹配ip地址的正则表达式。
  static bool isIP(String input) {
    return matches(RegexConstants.REGEX_IP, input);
  }

  /// Return whether input matches regex of username.
  /// 返回输入是否匹配用户名的正则表达式。
  static bool isUserName(String input,
      {String regex = RegexConstants.REGEX_USERNAME}) {
    return matches(regex, input);
  }

  /// Return whether input matches regex of QQ.
  /// 返回是否匹配QQ的正则表达式。
  static bool isQQ(String input) {
    return matches(RegexConstants.REGEX_QQ_NUM, input);
  }

  /// Return whether input matches the regex.
  /// 返回输入是否匹配正则表达式。
  static bool matches(String regex, String input) {
    if (input.isEmpty) {
      return false;
    }
    return RegExp(regex).hasMatch(input);
  }

  /// 判断内容是否符合正则（支持Pattern类型参数）
  static bool hasMatch(String? s, Pattern pattern) {
    if (s == null) return false;

    if (pattern is RegExp) {
      return pattern.hasMatch(s);
    } else if (pattern is String) {
      return RegExp(pattern).hasMatch(s);
    }
    return false;
  }

  /// 验证是否为纯数字（整数或小数）。
  ///
  /// 允许的形式：`123`、`-123`、`12.3`、`-12.3`、`.5`、`0.0`。
  /// 小数点后必须紧跟至少一位数字，因此 `"123."`（末尾孤立的小数点）会被拒绝。
  static bool isNumeric(String? s) {
    if (s == null || s.isEmpty) return false;
    const pattern = r'^-?(?:\d+(?:\.\d+)?|\.\d+)$';
    return hasMatch(s, pattern);
  }

  /// 验证是否为整数
  static bool isInteger(String? s) {
    if (s == null || s.isEmpty) return false;
    const pattern = r'^-?\d+$';
    return hasMatch(s, pattern);
  }

  /// 验证是否为正整数
  static bool isPositiveInteger(String? s) {
    if (s == null || s.isEmpty) return false;
    const pattern = r'^[1-9]\d*$';
    return hasMatch(s, pattern);
  }

  /// 验证是否为纯字母
  static bool isAlphabetic(String? s) {
    if (s == null || s.isEmpty) return false;
    const pattern = r'^[a-zA-Z]+$';
    return hasMatch(s, pattern);
  }

  /// 验证是否为字母和数字的组合
  static bool isAlphanumeric(String? s) {
    if (s == null || s.isEmpty) return false;
    const pattern = r'^[a-zA-Z0-9]+$';
    return hasMatch(s, pattern);
  }

  /// 验证密码强度（至少8位，包含大小写字母、数字和特殊字符）
  static bool isStrongPassword(String? password) {
    if (password == null || password.length < 8) return false;

    final hasUpper = hasMatch(password, r'[A-Z]');
    final hasLower = hasMatch(password, r'[a-z]');
    final hasDigits = hasMatch(password, r'\d');
    final hasSpecial = hasMatch(password, r'[!@#$%^&*(),.?":{}|<>]');

    return hasUpper && hasLower && hasDigits && hasSpecial;
  }

  /// 验证邮政编码（中国）
  static bool isPostalCode(String? code) {
    const pattern = r'^\d{6}$';
    return hasMatch(code, pattern);
  }

  /// 验证IP地址（IPv4）
  static bool isIPv4(String? ip) {
    const pattern =
        r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';
    return hasMatch(ip, pattern);
  }

  /// 验证IPv6地址
  static bool isIPv6(String? ip) {
    const pattern =
        r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$';
    return hasMatch(ip, pattern);
  }

  /// 验证MAC地址
  static bool isMACAddress(String? mac) {
    const pattern = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$';
    return hasMatch(mac, pattern);
  }

  /// 验证时间格式 (HH:MM:SS)
  static bool isTime(String? time) {
    const pattern = r'^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$';
    return hasMatch(time, pattern);
  }

  /// 验证十六进制颜色值 (#RGB, #RGBA, #RRGGBB, #RRGGBBAA)
  static bool isHexColor(String? color) {
    const pattern =
        r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8}|[A-Fa-f0-9]{4})$';
    return hasMatch(color, pattern);
  }

  /// 验证是否为有效的 JSON 格式。
  ///
  /// 仅当输入能解析为 JSON **对象**（`Map`）或 **数组**（`List`）时返回 `true`。
  /// 这是 `isJSON` 最常见的使用场景（校验接口返回体等结构化数据）。
  ///
  /// 一致地拒绝所有 JSON 标量：数字 / 布尔 / 字符串 / `null`。早期实现把
  /// `"123"` 当成合法 JSON（`json.decode` 得到非 null 的 `int`），却把
  /// `"null"` 当成非法（因为 `json.decode("null") == null`），语义不一致；
  /// 现统一为「只接受对象/数组」。
  static bool isJSON(String? str) {
    if (str == null || str.isEmpty) return false;
    try {
      final parsed = json.decode(str);
      return parsed is Map || parsed is List;
    } catch (e) {
      return false;
    }
  }
}

/// id card province dict.
final List<String> ID_CARD_PROVINCE_DICT = [
  '11=北京',
  '12=天津',
  '13=河北',
  '14=山西',
  '15=内蒙古',
  '21=辽宁',
  '22=吉林',
  '23=黑龙江',
  '31=上海',
  '32=江苏',
  '33=浙江',
  '34=安徽',
  '35=福建',
  '36=江西',
  '37=山东',
  '41=河南',
  '42=湖北',
  '43=湖南',
  '44=广东',
  '45=广西',
  '46=海南',
  '50=重庆',
  '51=四川',
  '52=贵州',
  '53=云南',
  '54=西藏',
  '61=陕西',
  '62=甘肃',
  '63=青海',
  '64=宁夏',
  '65=新疆',
  '71=台湾老',
  '81=香港',
  '82=澳门',
  '83=台湾新',
  '91=国外',
];
