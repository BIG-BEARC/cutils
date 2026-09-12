import 'dart:convert';

import 'package:cutils/log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 18-07-2024 10:45
/// * @Email:
/// * description json转化工具类，主要是负责list，map，对象和json之间转化等

class JsonUtils {
  JsonUtils._();

  /// 以日志方式输出 JSON 字符串（支持缩进）。
  ///
  /// 原方法名 `printJson` 踩 CLAUDE.md 日志禁词（`print`），故重命名为 `logJson`。
  /// `printJson` 已保留为 deprecated 别名以避免下游硬断裂。
  static void logJson(dynamic obj, {bool prettyPrint = true}) {
    try {
      if (prettyPrint) {
        const encoder = JsonEncoder.withIndent('  ');
        logger.i(encoder.convert(obj));
      } else {
        logger.i(json.encode(obj));
      }
    } catch (e) {
      logger.e('JSON 打印失败: $e');
    }
  }

  /// Deprecated：使用 [logJson] 代替。
  @Deprecated('使用 logJson 代替。printJson 命名踩日志禁词（print），'
      '已重命名为 logJson。')
  static void printJson(dynamic obj, {bool prettyPrint = true}) =>
      logJson(obj, prettyPrint: prettyPrint);

  /// 将任意对象转为 JSON 字符串
  static String? encodeObj(dynamic value) {
    if (value == null) return null;
    try {
      return json.encode(value);
    } catch (e, stackTrace) {
      logger.e('JSON 编码失败: value:$value $e\n$stackTrace');
      return null;
    }
  }

  /// 将单个对象转为 JSON 字符串
  static String? encodeObject<T>(
      T? obj, Map<String, dynamic> Function(T) toJson) {
    if (obj == null) return null;
    try {
      return json.encode(toJson(obj));
    } catch (e) {
      logger.e('JSON 单个对象编码失败: $e');
      return null;
    }
  }

  /// JSON 字符串转为对象。
  ///
  /// ⚠️ 精度限制：底层 `dart:convert` 的 `json.decode` 会把 JSON 数字解析为
  /// Dart 的 `int`/`double`。当整数大于 2^53（9007199254740992）时，可能因
  /// 浮点表示而丢失精度。如需精确的大整数，请在源头以字符串承载该字段，
  /// 再在 [fromMap] 内自行解析为 `BigInt`。
  static T? fromJson<T>(
      String? jsonStr, T Function(Map<String, dynamic> map) fromMap) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = json.decode(jsonStr);
      if (map is! Map<String, dynamic>) return null;
      return fromMap(map);
    } catch (e) {
      logger.e('JSON 解析失败: $e, 数据: $jsonStr');
      return null;
    }
  }

  /// 将 `List<dynamic>` 序列化为 JSON 字符串。`null` 返回 `null`；编码失败
  /// 记录错误日志并返回 `null`。
  static String? encodeList(List<dynamic>? list) {
    if (list == null) return null;
    try {
      return json.encode(list);
    } catch (e) {
      logger.e('JsonUtils encodeList error: $e');
      return null;
    }
  }

  /// 将对象列表转为 JSON 字符串。
  ///
  /// 空列表返回 `"[]"`（而非 null），以保持「列表」语义；仅 `null` 输入返回 `null`。
  static String? encodeObjectList<T>(
      List<T>? list, Map<String, dynamic> Function(T) toJson) {
    if (list == null) return null;
    try {
      final encoded = list.map((item) => toJson(item)).toList();
      return json.encode(encoded);
    } catch (e) {
      logger.e('JsonUtils encodeObjectList error: $e');
      return null;
    }
  }

  /// JSON 字符串或列表转为对象列表。
  ///
  /// ⚠️ 精度限制：同 [fromJson]——大于 2^53 的整数会丢失精度，需要精确大整数时
  /// 请以字符串承载并在 `fromMap` 内用 `BigInt` 解析。
  static List<T>? listFromJson<T>(
    dynamic source,
    T Function(Map<String, dynamic> map) fromMap,
  ) {
    if (source == null) return null;
    try {
      List<dynamic> list;
      if (source is String) {
        list = json.decode(source) as List<dynamic>;
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
      logger.e('JSON 列表解析失败: $e\n源数据: $source\n$stackTrace');
      return null;
    }
  }

  /// JSON 字符串转为 Map。
  ///
  /// ⚠️ 精度限制：同 [fromJson]——大于 2^53 的整数会丢失精度。
  static Map<String, dynamic>? toMap(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = json.decode(jsonStr);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      logger.e('JSON 转 Map 失败: $e');
      return null;
    }
  }

  /// JSON 字符串转为 List<Map>。
  ///
  /// ⚠️ 精度限制：同 [fromJson]——大于 2^53 的整数会丢失精度。
  static List<Map<String, dynamic>>? toMapList(String? jsonStr) {
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
      logger.e('JSON 转 Map 列表失败: $e');
      return null;
    }
  }
}
