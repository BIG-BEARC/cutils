import 'package:decimal/decimal.dart';
import 'package:cutils/ext/ext_fun.dart';

/// * @Author: chuxiong
/// * @Created at: 23-07-2025 17:32
/// * @Email:
/// * description
class NumUtils {
  NumUtils._();

  /// Checks if string is int or double.
  /// 检查字符串是int还是double
  static bool isNum(String s) {
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
  static num? getNumByValueString(String valueStr, {int? fractionDigits}) {
    double? value = double.tryParse(valueStr);
    return fractionDigits == null
        ? value
        : getNumByValueDouble(value, fractionDigits);
  }

  /// 浮点数字保留x位小数
  static num? getNumByValueDouble(double? value, int fractionDigits) {
    if (value == null) return null;
    String valueStr = value.toStringAsFixed(fractionDigits);
    return fractionDigits == 0
        ? int.tryParse(valueStr)
        : double.tryParse(valueStr);
  }

  /// get int by value string
  /// 将数字字符串转int
  static int getIntByValueString(String valueStr, {int defValue = 0}) {
    return int.tryParse(valueStr) ?? defValue;
  }

  /// get double by value str.
  /// 数字字符串转double
  static double getDoubleByValueString(String valueStr, {double defValue = 0}) {
    return double.tryParse(valueStr) ?? defValue;
  }

  /// isZero
  /// 判断是否是否是0
  static bool isZero(num? value) {
    return value == null || value == 0;
  }

  /// add (without loosing precision).
  /// 两个数相加（防止精度丢失）
  ///
  /// Throws [ArgumentError] if either operand cannot be parsed as a
  /// precise [Decimal] (e.g. non-finite doubles). The silent `0.0`
  /// fallback is intentionally removed so misuse surfaces.
  static double addNum(num a, num b) {
    final result = addDec(a, b);
    if (result == null) {
      throw ArgumentError(
        'addNum: operands must be finite numbers (a=$a, b=$b)',
      );
    }
    return result.toDouble();
  }

  /// subtract (without loosing precision).
  /// 两个数相减（防止精度丢失）
  ///
  /// Throws [ArgumentError] if either operand cannot be parsed as a
  /// precise [Decimal] (e.g. non-finite doubles).
  static double subtractNum(num a, num b) {
    final result = subtractDec(a, b);
    if (result == null) {
      throw ArgumentError(
        'subtractNum: operands must be finite numbers (a=$a, b=$b)',
      );
    }
    return result.toDouble();
  }

  /// multiply (without loosing precision).
  /// 两个数相乘（防止精度丢失）
  ///
  /// Throws [ArgumentError] if either operand cannot be parsed as a
  /// precise [Decimal] (e.g. non-finite doubles).
  static double multiplyNum(num a, num b) {
    final result = multiplyDec(a, b);
    if (result == null) {
      throw ArgumentError(
        'multiplyNum: operands must be finite numbers (a=$a, b=$b)',
      );
    }
    return result.toDouble();
  }

  /// divide (without loosing precision).
  /// 两个数相除（防止精度丢失）
  ///
  /// Throws [ArgumentError] if either operand cannot be parsed as a
  /// precise [Decimal] (e.g. non-finite doubles), or if [b] is zero.
  static double divideNum(num a, num b) {
    final result = divideDec(a, b);
    if (result == null) {
      throw ArgumentError(
        'divideNum: operands must be finite numbers and divisor non-zero '
        '(a=$a, b=$b)',
      );
    }
    return result.toDouble();
  }

  /// 加 (精确相加,防止精度丢失).
  /// add (without loosing precision).
  static Decimal? addDec(num a, num b) {
    return addDecString(a.toString(), b.toString());
  }

  /// 减 (精确相减,防止精度丢失).
  /// subtract (without loosing precision).
  static Decimal? subtractDec(num a, num b) {
    return subtractDecString(a.toString(), b.toString());
  }

  /// 乘 (精确相乘,防止精度丢失).
  /// multiply (without loosing precision).
  static Decimal? multiplyDec(num a, num b) {
    return multiplyDecString(a.toString(), b.toString());
  }

  /// 除 (精确相除,防止精度丢失).
  /// divide (without loosing precision).
  static Decimal? divideDec(num a, num b) {
    return divideDecString(a.toString(), b.toString());
  }

  /// 余数
  static Decimal? remainder(num a, num b) {
    return remainderDecString(a.toString(), b.toString());
  }

  /// Relational less than operator.
  /// 关系小于运算符。判断a是否小于b
  static bool lessThan(num a, num b) {
    return lessThanDecString(a.toString(), b.toString());
  }

  /// Relational less than or equal operator.
  /// 关系小于或等于运算符。判断a是否小于或者等于b
  static bool thanOrEqual(num a, num b) {
    return thanOrEqualDecString(a.toString(), b.toString());
  }

  /// Relational greater than operator.
  /// 关系大于运算符。判断a是否大于b
  static bool greaterThan(num a, num b) {
    return greaterThanDecString(a.toString(), b.toString());
  }

  /// Relational greater than or equal operator.
  static bool greaterOrEqual(num a, num b) {
    return greaterOrEqualDecString(a.toString(), b.toString());
  }

  // 封装安全解析方法
  static Decimal? _safeParseDecimal(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Decimal.tryParse(value);
  }

  /// 两个数相加（防止精度丢失）
  static Decimal? addDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal + bDecimal;
  }

  /// 减
  static Decimal? subtractDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal - bDecimal;
  }

  /// 乘
  static Decimal? multiplyDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal * bDecimal;
  }

  /// 除
  ///
  /// Non-terminating quotients (e.g. `1/3`) are truncated to 20
  /// significant decimal places via `scaleOnInfinitePrecision` so the
  /// precise API returns a finite [Decimal] instead of throwing.
  static Decimal? divideDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null || bDecimal == Decimal.zero) {
      return null;
    }
    return (aDecimal / bDecimal).toDecimal(scaleOnInfinitePrecision: 20);
  }

  /// 余数
  static Decimal? remainderDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null || bDecimal == Decimal.zero) {
      return null;
    }
    return aDecimal % bDecimal;
  }

  /// Relational less than operator.
  /// 判断a是否小于b
  static bool lessThanDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal < bDecimal;
  }

  /// Relational less than or equal operator.
  /// 判断a是否小于或者等于b
  static bool thanOrEqualDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal <= bDecimal;
  }

  /// Relational greater than operator.
  /// 判断a是否大于b
  static bool greaterThanDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal > bDecimal;
  }

  /// Relational greater than or equal operator.
  static bool greaterOrEqualDecString(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return false;
    return aDecimal >= bDecimal;
  }

  /// Checks if num a LOWER than num b.
  /// 检查num a是否小于num b。
  static bool isLowerThan(num a, num b) => a < b;

  /// Checks if num a GREATER than num b.
  /// 检查num a是否大于num b。
  static bool isGreaterThan(num a, num b) => a > b;

  /// Checks if num a EQUAL than num b.
  /// 检查num a是否等于num b。
  static bool isEqual(num a, num b) => a == b;
}
