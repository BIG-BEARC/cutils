/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:05 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
/// bool 扩展：提供取反、逻辑运算、条件取值与类型转换等便捷方法。
extension BoolExt on bool {
  /// 逻辑取反（等价于 `!this`，便于链式调用）。
  bool get not => !this;

  /// 逻辑与（等价于 `this && other`，可用作中缀运算符 `a & b`）。
  bool operator &(bool other) => this && other;

  /// 逻辑或（等价于 `this || other`，可用作中缀运算符 `a | b`）。
  bool operator |(bool other) => this || other;

  /// 当本值为 `true` 时返回 [value]，否则返回 `null`。
  ///
  /// example:
  /// ```dart
  /// final isAdmin = true;
  /// final role = isAdmin.ifTrue('Admin'); // 'Admin'
  /// ```
  T? ifTrue<T>(T value) => this ? value : null;

  /// 当本值为 `false` 时返回 [value]，否则返回 `null`。
  T? ifFalse<T>(T value) => this ? null : value;

  /// 条件返回值：`true` 返回 [ifTrueValue]，`false` 返回 [ifFalseValue]。
  ///
  /// example:
  /// ```dart
  /// final role = isAdmin.ifElse('Admin', 'User');
  /// ```
  T ifElse<T>(T ifTrueValue, T ifFalseValue) =>
      this ? ifTrueValue : ifFalseValue;

  /// 转为整数：`true` → `1`，`false` → `0`。
  int get toInt => this ? 1 : 0;

  /// 转为字符串：`'true'` / `'false'`（与 `toString()` 等价的语义化别名）。
  String get toStringVal => this ? 'true' : 'false';
}
