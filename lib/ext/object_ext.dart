/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:06 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///Object扩展：
extension ObjectExt on Object? {
  /// 是否为 null 或「空白」。
  ///
  /// - null → true
  /// - 空字符串 / 空 Iterable / 空 Map → true
  /// - 其它（包括 `0`、`false`）→ false
  ///
  /// BREAKING: 历史实现把任何 `num == 0`（含 `0`、`0.0`）当作空白，
  /// 这会误判合法的零值；现已移除该分支，数字不再被视为空白。
  /// 同时删除了 `this is! bool` 这一死分支（bool 不是 num 的子类型）。
  bool isNullOrBlank() {
    if (this == null) return true;
    if (this is String) return (this as String).isEmpty;
    if (this is Iterable) return (this as Iterable).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    return false;
  }

  /// 判断本对象是否为 null。
  bool get isNull => this == null;

  /// 判断本对象是否非 null。
  bool get isNotNull => this != null;

  /// 判断本对象是否是指定类型 [T]。
  ///
  /// example:
  /// ```dart
  /// final value = 'hello';
  /// value.isTypeOf<String>(); // true
  /// value.isTypeOf<int>();    // false
  /// ```
  bool isTypeOf<T>() => this is T;
}
