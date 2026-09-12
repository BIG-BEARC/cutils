import 'package:decimal/decimal.dart';
import 'package:cutils/ext/ext_fun.dart';

/// * @Author: chuxiong
/// * @Created at: 23-07-2025 17:32
/// * @Email:
/// * description
/// 数值工具：基于 [Decimal] 提供防精度丢失的加减乘除与关系运算。
///
/// 命名约定：
/// - `*Num`：入参 `num`，返回 `double`。运算抛 [ArgumentError]（非静默 0.0），
///   但最终 `.toDouble()` 仍有损——详见 [addNum] 的精度说明。
/// - `*Dec`：入参 `num`，返回 `String?`（精确十进制字符串；`Decimal` 为内部实现，
///   不出现在公开签名——失败返回 `null`）。
/// - `*DecString`：入参 / 出参均为字符串，精度最高的入口，建议金额计算优先用此族。
class NumUtils {
  NumUtils._();

  /// Checks if string is int or double.
  /// 检查字符串是int还是double
  static bool isNum(String s) {
    if (s.isNull) {
      return false;
    }
    final parseNum = num.tryParse(s);
    if (parseNum.isNull) {
      return false;
    }
    return parseNum is num;
  }

  /// 将数字字符串转num，数字保留x位小数
  static num? getNumByValueString(String valueStr, {int? fractionDigits}) {
    final double? value = double.tryParse(valueStr);
    return fractionDigits == null
        ? value
        : getNumByValueDouble(value, fractionDigits);
  }

  /// 浮点数字保留x位小数
  static num? getNumByValueDouble(double? value, int fractionDigits) {
    if (value == null) return null;
    final String valueStr = value.toStringAsFixed(fractionDigits);
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
  ///
  /// Precision caveat: operands are routed through `a.toString()` and
  /// parsed back as a [Decimal]. For a literal like `0.1` the display
  /// value is `"0.1"` and the result is exact, but an *already-computed*
  /// double such as `0.1 + 0.2` (whose value is `0.30000000000000004`)
  /// is parsed at that long display value, carrying the floating-point
  /// drift into the result. The final `.toDouble()` step can also lose
  /// precision for very large magnitudes. When exactness matters, prefer
  /// [addDecString] / [addDec] (exact decimal strings) and
  /// pass string operands directly.
  static double addNum(num a, num b) {
    final result = _addDecimal(a.toString(), b.toString());
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
  ///
  /// Precision caveat: see [addNum]. Operands are parsed from their
  /// `toString()` display value, so already-computed doubles carry their
  /// floating-point drift, and the final `.toDouble()` can lose precision
  /// for large magnitudes. Prefer [subtractDecString] / [subtractDec]
  /// with string operands when exactness matters.
  static double subtractNum(num a, num b) {
    final result = _subtractDecimal(a.toString(), b.toString());
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
  ///
  /// Precision caveat: see [addNum]. Operands are parsed from their
  /// `toString()` display value, so already-computed doubles carry their
  /// floating-point drift, and the final `.toDouble()` can lose precision
  /// for large magnitudes. Prefer [multiplyDecString] / [multiplyDec]
  /// with string operands when exactness matters.
  static double multiplyNum(num a, num b) {
    final result = _multiplyDecimal(a.toString(), b.toString());
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
  ///
  /// Precision caveat: see [addNum]. Operands are parsed from their
  /// `toString()` display value, so already-computed doubles carry their
  /// floating-point drift, and the final `.toDouble()` can lose precision
  /// for large magnitudes. Prefer [divideDecString] / [divideDec]
  /// with string operands when exactness matters.
  static double divideNum(num a, num b) {
    final result = _divideDecimal(a.toString(), b.toString());
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
  ///
  /// 返回十进制字符串；操作数无法精确解析时返回 `null`。
  static String? addDec(num a, num b) {
    return addDecString(a.toString(), b.toString());
  }

  /// 减 (精确相减,防止精度丢失).
  /// subtract (without loosing precision).
  ///
  /// 返回十进制字符串；操作数无法精确解析时返回 `null`。
  static String? subtractDec(num a, num b) {
    return subtractDecString(a.toString(), b.toString());
  }

  /// 乘 (精确相乘,防止精度丢失).
  /// multiply (without loosing precision).
  ///
  /// 返回十进制字符串；操作数无法精确解析时返回 `null`。
  static String? multiplyDec(num a, num b) {
    return multiplyDecString(a.toString(), b.toString());
  }

  /// 除 (精确相除,防止精度丢失).
  /// divide (without loosing precision).
  ///
  /// 返回十进制字符串；操作数无法精确解析或除数为 0 时返回 `null`。
  static String? divideDec(num a, num b) {
    return divideDecString(a.toString(), b.toString());
  }

  /// 余数
  ///
  /// 返回十进制字符串；操作数无法精确解析或除数为 0 时返回 `null`。
  static String? remainder(num a, num b) {
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

  // 私有 Decimal 内部实现：供 *Num 族与 *DecString 族共用，
  // [Decimal] 不出现在公开签名中。
  static Decimal? _addDecimal(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal + bDecimal;
  }

  static Decimal? _subtractDecimal(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal - bDecimal;
  }

  static Decimal? _multiplyDecimal(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null) return null;
    return aDecimal * bDecimal;
  }

  /// Non-terminating quotients (e.g. `1/3`) are truncated to 20
  /// significant decimal places via `scaleOnInfinitePrecision` so the
  /// precise API returns a finite value instead of throwing.
  static Decimal? _divideDecimal(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null || bDecimal == Decimal.zero) {
      return null;
    }
    return (aDecimal / bDecimal).toDecimal(scaleOnInfinitePrecision: 20);
  }

  static Decimal? _remainderDecimal(String a, String b) {
    final aDecimal = _safeParseDecimal(a);
    final bDecimal = _safeParseDecimal(b);
    if (aDecimal == null || bDecimal == null || bDecimal == Decimal.zero) {
      return null;
    }
    return aDecimal % bDecimal;
  }

  /// 两个数相加（防止精度丢失），返回十进制字符串；解析失败返回 `null`。
  static String? addDecString(String a, String b) {
    return _addDecimal(a, b)?.toString();
  }

  /// 减，返回十进制字符串；解析失败返回 `null`。
  static String? subtractDecString(String a, String b) {
    return _subtractDecimal(a, b)?.toString();
  }

  /// 乘，返回十进制字符串；解析失败返回 `null`。
  static String? multiplyDecString(String a, String b) {
    return _multiplyDecimal(a, b)?.toString();
  }

  /// 除，返回十进制字符串。
  ///
  /// Non-terminating quotients (e.g. `1/3`) are truncated to 20
  /// significant decimal places (see [_divideDecimal]) so the result
  /// is finite instead of throwing. 除数为 0 或解析失败返回 `null`。
  static String? divideDecString(String a, String b) {
    return _divideDecimal(a, b)?.toString();
  }

  /// 余数，返回十进制字符串；解析失败或除数为 0 返回 `null`。
  static String? remainderDecString(String a, String b) {
    return _remainderDecimal(a, b)?.toString();
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
