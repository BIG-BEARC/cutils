import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cutils/json/json_utils.dart';
import 'package:cutils/log/log.dart';


/// * @Author: chuxiong
/// * @Created at: 12-06-2025 11:11
/// * @Email:
/// * description sp存储工具类，适合存储轻量级数据，不建议存储json长字符串

final spUtil = SpUtil();

class SpUtil {
  SpUtil._();

  static final SpUtil _instance = SpUtil._();

  factory SpUtil() => _instance;
  SharedPreferences? _prefs;

  Future<SharedPreferences?> init() async {
    if (_prefs != null) {
      return _prefs;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs;
  }

  Future<void> ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// 封装 put 操作，自动检查初始化
  Future<bool> _put(String key, dynamic value) async {
    await ensureInitialized();
    logger.i("_put key:$key value:$value");
    try {
      return _prefs?.setString(key, json.encode(value)) ?? Future.value(false);
    } catch (e) {
      logger.e("SpUtil error _put for key '$key ,value:$value\n error:$e");
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
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return fromJson(jsonMap);
    } catch (e, stackTrace) {
      logger.e("SpUtil error reading key '$key': $e\n$stackTrace");
      return defValue;
    }
  }

  /// 存储对象
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
  // await spUtil.putObject("user", user.toJson());
  // User? loadedUser = spUtil.getObject("user", User.fromJson);
  Future<bool> putObject(String key, Object value) => _put(key, value);

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
            (e) => jsonUtil.encodeObj(e),
          )
          .where((e) => e != null)
          .cast<String>()
          .toList();
      return _prefs?.setStringList(key, encodedList) ?? false;
    } catch (e) {
      logger.e("SpUtil error putObjectList list for key '$key ,list:$list\n error:$e");
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
          .map((str) => jsonUtil.fromJson<T>(str, fromJson))
          .whereType<T>()
          .toList();

      return decodedList;
    } catch (e, stackTrace) {
      logger.e("SpUtil error reading object list for key '$key': $e\n$stackTrace");
      return defValue;
    }
  }

  /// 存储字符串
  Future<bool> putString(String key, String value) async {
    await ensureInitialized();
    logger.i("putString key:$key value:$value");
    return _prefs?.setString(key, value) ?? false;
  }

  /// 获取字符串
  String? getString(String key, {String? defValue = ''}) {
     var value = _prefs?.getString(key) ?? defValue;
     logger.i("getString key:$key value:$value");
     return value;
  }

  /// 存储布尔值
  Future<bool> putBool(String key, bool value) async {
    await ensureInitialized();
    logger.i("putBool key:$key value:$value");
    return _prefs?.setBool(key, value) ?? false;
  }

  /// 获取布尔值
  bool? getBool(String key, {bool defValue = false}) {
    final value =  _prefs?.getBool(key) ?? defValue;
    logger.i("getBool key:$key value:$value");
    return value;
  }

  /// 存储整数
  Future<bool> putInt(String key, int value) async {
    await ensureInitialized();
    logger.i("putInt key:$key value:$value");
    return _prefs?.setInt(key, value) ?? false;
  }

  /// 获取整数
  int? getInt(String key, {int defValue = 0}) {
    final  value = _prefs?.getInt(key) ?? defValue;
    logger.i("getInt key:$key value:$value");
    return value;
  }

  /// 存储浮点数
  Future<bool> putDouble(String key, double value) async {
    await ensureInitialized();
    logger.i("putDouble key:$key value:$value");
    return _prefs?.setDouble(key, value) ?? false;
  }

  /// 获取浮点数
  double? getDouble(String key, {double defValue = 0.0}) {
    final  value = _prefs?.getDouble(key) ?? defValue;
    logger.i("getDouble key:$key value:$value");
    return value;
  }

  /// 存储字符串列表
  Future<bool> putStringList(String key, List<String> value) async {
    await ensureInitialized();
    logger.i("putStringList key:$key value:$value");
    return _prefs?.setStringList(key, value) ?? false;
  }

  /// 获取字符串列表
  List<String>? getStringList(String key, {List<String>? defValue = const []}) {
    final  value = _prefs?.getStringList(key) ?? defValue;
    logger.i("getStringList key:$key value:$value");
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
