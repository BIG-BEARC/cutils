import 'package:decimal/decimal.dart';
import 'package:cutils/ext/ext_fun.dart';

/// * @Author: chuxiong
/// * @Created at: 23-07-2025 17:32
/// * @Email:
/// * description
final numUtils = NumUtils();

class NumUtils {
  NumUtils._();

  static final _ins = NumUtils._();

  factory NumUtils() => _ins;

  /// Checks if string is int or double.
  /// 检查字符串是int还是double
  bool isNum(String s) {
    if (s.isNull) {
      return false;
    }
    var parseNum = num.tryParse(s);
    if (parseNum.isNull) {
      return false;
    }
    return parseNum is num;
  }

  /// 将数字字符串转num，数字保留x位小数
  num? getNumByValueString(String valueStr, {int? fractionDigits}) {
    double? value = double.tryParse(valueStr);
    return fractionDigits == null ? value : getNumByValueDouble(value, fractionDigits);
  }

  /// 浮点数字保留x位小数
  num? getNumByValueDouble(double? value, int fractionDigits) {
    if (value == null) return null;
    String valueStr = value.toStringAsFixed(fractionDigits);
    return fractionDigits == 0 ? int.tryParse(valueStr) : double.tryParse(valueStr);
  }

  /// get int by value string
  /// 将数字字符串转int
  int getIntByValueString(String valueStr, {int defValue = 0}) {
    return int.tryParse(valueStr) ?? defValue;
  }

  /// get double by value str.
  /// 数字字符串转double
  double getDoubleByValueString(String valueStr, {double defValue = 0}) {
    return double.tryParse(valueStr) ?? defValue;
  }

  /// isZero
  /// 判断是否是否是0
  bool isZero(num? value) {
    return value == null || value == 0;
  }

  /// add (without loosing precision).
  /// 两个数相加（防止精度丢失）
  double addNum(num a, num b) {
    return addDec(a, b)?.toDouble() ?? 0.0;
  }

  /// subtract (without loosing precision).
  /// 两个数相减（防止精度丢失）
  double subtractNum(num a, num b) {
    return subtractDec(a, b)?.toDouble() ?? 0.0;
  }

  /// multiply (without loosing precision).
  /// 两个数相乘（防止精度丢失）
  double multiplyNum(num a, num b) {
    return multiplyDec(a, b)?.toDouble() ?? 0.0;
  }

  /// divide (without loosing precision).
  /// 两个数相除（防止精度丢失）
  double divideNum(num a, num b) {
    return divideDec(a, b)?.toDouble() ?? 0.0;
  }

  /// 加 (精确相加,防止精度丢失).
  /// add (without loosing precision).
  Decimal? addDec(num a, num b) {
    return addDecString(a.toString(), b.toString());
  }

  /// 减 (精确相减,防止精度丢失).
  /// subtract (without loosing precision).
  Decimal? subtractDec(num a, num b) {
    return subtractDecString(a.toString(), b.toString());
  }

  /// 乘 (精确相乘,防止精度丢失).
  /// multiply (without loosing precision).
  Decimal? multiplyDec(num a, num b) {
    return multiplyDecString(a.toString(), b.toString());
  }

  /// 除 (精确相除,防止精度丢失).
  /// divide (without loosing precision).
  Decimal? divideDec(num a, num b) {
    return divideDecString(a.toString(), b.toString());
  }

  /// 余数
  Decimal? remainder(num a, num b) {
    return remainderDecString(a.toString(), b.toString());
  }

  /// Relational less than operator.
  /// 关系小于运算符。判断a是否小于b
  bool lessThan(num a, num b) {
    return lessThanDecString(a.toString(), b.toString());
  }

  /// Relational less than or equal operator.
  /// 关系小于或等于运算符。判断a是否小于或者等于b
  bool thanOrEqual(num a, num b) {
    return thanOrEqualDecString(a.toString(), b.toString());
  }

  /// Relational greater than operator.
  /// 关系大于运算符。判断a是否大于b
  bool greaterThan(num a, num b) {
    return greaterThanDecString(a.toString(), b.toString());
  }

  /// Relational greater than or equal operator.
  bool greaterOrEqual(num a, num b) {
    return greaterOrEqualDecString(a.toString(), b.toString());
  }

  // 封装安全解析方法
  Decimal? _safeParseDecimal(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Decimal.tryParse(value);
  }

  /// 两个数相加（防止精度丢失）
  Decimal? addDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal + bDecimal;
  }

  /// 减
  Decimal? subtractDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal - bDecimal;
  }

  /// 乘
  Decimal? multiplyDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal * bDecimal;
  }

  /// 除
  Decimal? divideDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null || bDecimal == Decimal.zero) return null;
    return (aDecimal / bDecimal).toDecimal();
  }

  /// 余数
  Decimal? remainderDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null || bDecimal == Decimal.zero) return null;
    return aDecimal % bDecimal;
  }

  /// Relational less than operator.
  /// 判断a是否小于b
  bool lessThanDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal < bDecimal;
  }

  /// Relational less than or equal operator.
  /// 判断a是否小于或者等于b
  bool thanOrEqualDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal <= bDecimal;
  }

  /// Relational greater than operator.
  /// 判断a是否大于b
  bool greaterThanDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal > bDecimal;
  }

  /// Relational greater than or equal operator.
  bool greaterOrEqualDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal >= bDecimal;
  }

  /// Checks if num a LOWER than num b.
  /// 检查num a是否小于num b。
  bool isLowerThan(num a, num b) => a < b;

  /// Checks if num a GREATER than num b.
  /// 检查num a是否大于num b。
  bool isGreaterThan(num a, num b) => a > b;

  /// Checks if num a EQUAL than num b.
  /// 检查num a是否等于num b。
  bool isEqual(num a, num b) => a == b;
}