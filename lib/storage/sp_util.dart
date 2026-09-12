// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:cutils/json/json_utils.dart';
import 'package:cutils/log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 12-06-2025 11:11
/// * @Email:
/// * description sp存储工具类，适合存储轻量级数据，不建议存储json长字符串

/// 全局 [SpUtil] 单例。使用前需先 `await spUtil.init();`。
final spUtil = SpUtil();

/// SharedPreferences 薄封装单例。
///
/// `putJsonable` / `getObject` 系列把可 JSON 编码的对象序列化后落地；
/// `putString` / `getBool` 等基本类型直接转发到 [SharedPreferences]。
/// 日志只记录 key（不记录 value），避免 token / PII 入日志。
/// 并发 [init] 由 single-flight Future 去重。
class SpUtil {
  SpUtil._();

  static final SpUtil _instance = SpUtil._();

  factory SpUtil() => _instance;
  SharedPreferences? _prefs;
  // 缓存进行中的初始化 Future，确保并发 init() 调用只触发一次
  // SharedPreferences.getInstance()。完成或失败后清空。
  Future<bool>? _initFuture;

  /// 初始化 SharedPreferences（single-flight：并发调用共享同一次 getInstance）。
  ///
  /// 完成后缓存到 `_prefs`；失败清空 in-flight Future 允许重试。app 启动时
  /// 调用一次即可。
  ///
  /// 返回 `true` 表示初始化成功（`SharedPreferences` 对象不外泄，
  /// 需要原始实例时用 [getSp]）。
  Future<bool> init() async {
    if (_prefs != null) return true;
    // 并发调用者共享同一个 in-flight Future（single-flight），避免各自调用
    // getInstance()。
    if (_initFuture != null) return _initFuture!;
    final Future<bool> pending = SharedPreferences.getInstance().then((p) {
      _prefs = p;
      _initFuture = null;
      return true;
    }).catchError((Object e) {
      // 失败时清空，允许后续重试。
      _initFuture = null;
      throw e;
    });
    _initFuture = pending;
    return pending;
  }

  /// 确保 [init] 已完成；若尚未初始化则等待其完成。供各 get/put 方法内部使用。
  Future<void> ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// 仅用于测试：重置单例持有的 SharedPreferences 缓存与 in-flight Future，
  /// 使下一个 init() 走冷启动路径。生产代码不得调用。
  @visibleForTesting
  void resetInstanceForTesting() {
    _prefs = null;
    _initFuture = null;
  }

  /// 封装 put 操作，自动检查初始化
  Future<bool> _put(String key, dynamic value) async {
    await ensureInitialized();
    // 仅记录 key，避免把敏感 value（token/PII）打入日志。
    logger.i('_put key:$key');
    try {
      return _prefs?.setString(key, json.encode(value)) ?? Future.value(false);
    } catch (e) {
      logger.e("SpUtil error _put for key '$key\n error:$e");
      return Future.value(false);
    }
  }

  /// 封装 get 操作并添加异常捕获
  T? _get<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    T? defValue,
  }) {
    try {
      final String? jsonString = _prefs?.getString(key);
      if (jsonString == null || jsonString.isEmpty) return defValue;
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (e, stackTrace) {
      logger.e("SpUtil error reading key '$key': $e\n$stackTrace");
      return defValue;
    }
  }

  /// 存储「可 JSON 编码」的对象（Map / 带 toJson 的对象 / List / 基本类型）。
  ///
  /// [value] 会被 `json.encode(value)` 序列化为字符串后落地，因此必须是一个
  /// 可被 `dart:convert` 编码的值——这正是「Jsonable」契约的由来。
  /// class User {
  //   final String name;
  //   final int age;
  //
  //   User({required this.name, required this.age});
  //
  //   Map<String, dynamic> toJson() => {'name': name, 'age': age};
  //
  //   factory User.fromJson(Map<String, dynamic> json) {
  //     return User(name: json['name'], age: json['age']);
  //   }
  // }
  // await spUtil.putJsonable("user", user.toJson());
  // User? loadedUser = spUtil.getObject("user", User.fromJson);
  Future<bool> putJsonable(String key, Object value) => _put(key, value);

  /// Deprecated：使用 [putJsonable] 代替。
  ///
  /// 原方法名 `putObject` 暗示可存「任意对象」，但实现会调用
  /// `json.encode(value)`，名不副实，故重命名为 [putJsonable]。
  @Deprecated('使用 putJsonable 代替。putObject 暗示可存任意对象，但实际会'
      'json.encode(value)，名不副实。')
  Future<bool> putObject(String key, Object value) => putJsonable(key, value);

  /// 获取对象
  T? getObject<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    T? defValue,
  }) {
    return _get<T>(key, fromJson, defValue: defValue);
  }

  /// 存储对象列表
  Future<bool> putObjectList(String key, List<Object> list) async {
    await ensureInitialized();
    try {
      final List<String> encodedList = list
          .map(
            (e) => JsonUtils.encodeObj(e),
          )
          .whereType<String>()
          .toList();
      return _prefs?.setStringList(key, encodedList) ?? false;
    } catch (e) {
      logger.e(
          "SpUtil error putObjectList list for key '$key ,list:$list\n error:$e");
      return false;
    }
  }

  /// 获取对象列表
  List<T>? getObjectList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    List<T>? defValue = const [],
  }) {
    try {
      final List<String>? encodedList = _prefs?.getStringList(key);
      if (encodedList == null || encodedList.isEmpty) return defValue;

      final List<T> decodedList = encodedList
          .map((str) => JsonUtils.fromJson<T>(str, fromJson))
          .whereType<T>()
          .toList();

      return decodedList;
    } catch (e, stackTrace) {
      logger.e(
          "SpUtil error reading object list for key '$key': $e\n$stackTrace");
      return defValue;
    }
  }

  /// 存储字符串
  Future<bool> putString(String key, String value) async {
    await ensureInitialized();
    logger.i('putString key:$key');
    return _prefs?.setString(key, value) ?? false;
  }

  /// 获取字符串
  String? getString(String key, {String? defValue = ''}) {
    final value = _prefs?.getString(key) ?? defValue;
    logger.i('getString key:$key');
    return value;
  }

  /// 存储布尔值
  Future<bool> putBool(String key, bool value) async {
    await ensureInitialized();
    logger.i('putBool key:$key');
    return _prefs?.setBool(key, value) ?? false;
  }

  /// 获取布尔值
  bool? getBool(String key, {bool defValue = false}) {
    final value = _prefs?.getBool(key) ?? defValue;
    logger.i('getBool key:$key');
    return value;
  }

  /// 存储整数
  Future<bool> putInt(String key, int value) async {
    await ensureInitialized();
    logger.i('putInt key:$key');
    return _prefs?.setInt(key, value) ?? false;
  }

  /// 获取整数
  int? getInt(String key, {int defValue = 0}) {
    final value = _prefs?.getInt(key) ?? defValue;
    logger.i('getInt key:$key');
    return value;
  }

  /// 存储浮点数
  Future<bool> putDouble(String key, double value) async {
    await ensureInitialized();
    logger.i('putDouble key:$key');
    return _prefs?.setDouble(key, value) ?? false;
  }

  /// 获取浮点数
  double? getDouble(String key, {double defValue = 0.0}) {
    final value = _prefs?.getDouble(key) ?? defValue;
    logger.i('getDouble key:$key');
    return value;
  }

  /// 存储字符串列表
  Future<bool> putStringList(String key, List<String> value) async {
    await ensureInitialized();
    logger.i('putStringList key:$key');
    return _prefs?.setStringList(key, value) ?? false;
  }

  /// 获取字符串列表
  List<String>? getStringList(String key, {List<String>? defValue = const []}) {
    final value = _prefs?.getStringList(key) ?? defValue;
    logger.i('getStringList key:$key');
    return value;
  }

  /// 是否包含指定键
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// 获取所有键
  Set<String>? getKeys() {
    return _prefs?.getKeys();
  }

  /// 移除某个键
  Future<bool> remove(String key) async {
    await ensureInitialized();
    return _prefs?.remove(key) ?? false;
  }

  /// 清空所有数据
  Future<bool> clear() async {
    await ensureInitialized();
    return _prefs?.clear() ?? false;
  }

  /// 重新加载数据（用于调试或热更新）
  Future<void> reload() async {
    await ensureInitialized();
    await _prefs?.reload();
  }

  /// 检查是否已初始化
  bool isInitialized() {
    return _prefs != null;
  }

  /// 获取原始 SharedPreferences 实例
  SharedPreferences? getSp() {
    return _prefs;
  }
}
