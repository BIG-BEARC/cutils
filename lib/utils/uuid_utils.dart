import 'package:uuid/uuid.dart';

/// * @Author: chuxiong
/// * @Created at: 20/12/2023 11:07
/// * @Email:
/// * description uuid工具类

final uuidUtil = UUIDUtils();

class UUIDUtils {
  UUIDUtils._();

  static final UUIDUtils _ins = UUIDUtils._();

  factory UUIDUtils() => _ins;
  final _uuid = const Uuid();

  final Map<String, String> _cache = {};

  /// 生成 UUID v1（基于时间）
  String generateV1() {
    return _uuid.v1();
  }

  /// 生成 UUID v4（基于随机数，常用）
  String generateV4() {
    return _uuid.v4();
  }

  /// 生成 UUID v5（基于命名空间和名称的哈希值）
  /// 让某个字符串生成一个 可预测、唯一且跨系统一致 的 UUID
  String generateV5(String namespace, String name) {
    if (_cache.containsKey(name)) return _cache[name]!;

    final uuid = _uuid.v5(namespace, name);
    _cache[name] = uuid;
    return uuid;
  }

  /// 清空缓存（可选）
  void clearCache() {
    _cache.clear();
  }
}
