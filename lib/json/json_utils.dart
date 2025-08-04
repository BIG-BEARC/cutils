import 'dart:convert';

import 'package:cutils/log/log.dart';


/// * @Author: chuxiong
/// * @Created at: 18-07-2024 10:45
/// * @Email:
/// * description json转化工具类，主要是负责list，map，对象和json之间转化等

final jsonUtil = JsonUtils();

class JsonUtils {
  JsonUtils._();

  static final _ins = JsonUtils._();

  factory JsonUtils() => _ins;

  /// 打印 JSON 字符串（支持缩进）
  void printJson(dynamic obj, {bool prettyPrint = true}) {
    try {
      if (prettyPrint) {
        const encoder = JsonEncoder.withIndent('  ');
        logger.i(encoder.convert(obj));
      } else {
        logger.i(json.encode(obj));
      }
    } catch (e) {
      logger.e("JSON 打印失败: $e");
    }
  }

  /// 将任意对象转为 JSON 字符串
  String? encodeObj(dynamic value) {
    if (value == null) return null;
    try {
      return json.encode(value);
    } catch (e, stackTrace) {
      logger.e("JSON 编码失败: value:$value $e\n$stackTrace");
      return null;
    }
  }

  /// 将单个对象转为 JSON 字符串
   String? encodeObject<T>(T? obj, Map<String, dynamic> Function(T) toJson) {
    if (obj == null) return null;
    try {
      return json.encode(toJson(obj));
    } catch (e) {
      logger.e('JSON 单个对象编码失败: $e');
      return null;
    }
  }
  /// JSON 字符串转为对象
  T? fromJson<T>(String? jsonStr, T Function(Map<String, dynamic> map) fromMap) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = json.decode(jsonStr);
      if (map is! Map<String, dynamic>) return null;
      return fromMap(map);
    } catch (e) {
      logger.e("JSON 解析失败: $e, 数据: $jsonStr");
      return null;
    }
  }


  String? encodeList(List<dynamic>? list) {
    if (list == null) return null;
    try {
      return json.encode(list);
    } catch (e) {
      logger.e('JsonUtils encodeList error: $e');
      return null;
    }
  }
   String? encodeObjectList<T>(List<T>? list, Map<String, dynamic> Function(T) toJson) {
    if (list == null || list.isEmpty) return null;
    try {
      final encoded = list.map((item) => toJson(item)).toList();
      return json.encode(encoded);
    } catch (e) {
      logger.e('JsonUtils encodeObjectList error: $e');
      return null;
    }
  }
  /// JSON 字符串或列表转为对象列表
  List<T>? listFromJson<T>(
    dynamic source,
    T Function(Map<String, dynamic> map) fromMap,
  ) {
    if (source == null) return null;
    try {
      List<dynamic> list;
      if (source is String) {
        list = json.decode(source);
      } else if (source is List) {
        list = source;
      } else {
        return null;
      }

      return list
          .map((item) {
            if (item is String) {
              final decoded = json.decode(item);
              if (decoded is Map<String, dynamic>) {
                return fromMap(decoded);
              }
            } else if (item is Map<String, dynamic>) {
              return fromMap(item);
            }
            return null;
          })
          .whereType<T>()
          .toList();
    } catch (e, stackTrace) {
      logger.e("JSON 列表解析失败: $e\n源数据: $source\n$stackTrace");
      return null;
    }
  }

  /// JSON 字符串转为 Map
  Map<String, dynamic>? toMap(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = json.decode(jsonStr);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      logger.e("JSON 转 Map 失败: $e");
      return null;
    }
  }

  /// JSON 字符串转为 List<Map>
  List<Map<String, dynamic>>? toMapList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! List) return null;

      return decoded
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e;
            } else if (e is String) {
              final innerDecoded = json.decode(e);
              return innerDecoded is Map<String, dynamic> ? innerDecoded : null;
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      logger.e("JSON 转 Map 列表失败: $e");
      return null;
    }
  }
}
