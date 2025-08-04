/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:06 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///Object扩展：
extension ObjectExt on Object? {
  bool isNullOrBlank() {
    if (this == null) return true;
    if (this is String) return (this as String).isEmpty;
    if (this is Iterable) return (this as Iterable).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    if (this is num && this is! bool) return (this as num) == 0;
    return false;
  }

  bool get isNull => this == null;

  bool get isNotNull => this != null;

  //final value = 'hello';
  // value.isTypeOf<String>(); // true
  // value.isTypeOf<int>();    // false
  bool isTypeOf<T>() => this is T;


}
