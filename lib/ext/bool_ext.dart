
/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:05 下午
/// * @Email: 
/// * @Company: 嘉联支付
/// * description
///bool扩展：
extension BoolExt on bool {
  // 取反
  bool get not => !this;

  // 与操作
  bool operator &(bool other) => this && other;

  // 或操作
  bool operator |(bool other) => this || other;

  // 条件返回值
  // final isAdmin = true;
  // final role = isAdmin.ifElse('Admin', 'User'); // 'Admin'
  // final name = isAdmin.ifTrue('Super User');    // 'Super User'
  T? ifTrue<T>(T value) => this ? value : null;

  T? ifFalse<T>(T value) => this ? null : value;

  T ifElse<T>(T ifTrueValue, T ifFalseValue) => this ? ifTrueValue : ifFalseValue;

  // 类型转换
  int get toInt => this ? 1 : 0;

  String get toStringVal => this ? 'true' : 'false';

  // 链式判断
  // 相当于：(value > 10 && value < 20 && value % 2 == 0)
  bool then(bool Function() action) {
    if (this) {
      return action();
    }
    return this;
  }
}
