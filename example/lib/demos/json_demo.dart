// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// JSON：[JsonUtils] 编码 / 解析为对象 / 解析为 Map。
class JsonDemo extends StatelessWidget {
  const JsonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const src = <String, dynamic>{'name': 'cutils', 'version': 1};
    final encoded = JsonUtils.encodeObj(src) ?? '(null)';
    const jsonStr = '{"name":"cutils","version":1}';
    final parsed = JsonUtils.fromJson<_DemoUser>(jsonStr, _DemoUser.fromMap);
    final asMap = JsonUtils.toMap(jsonStr);

    return DemoScaffold(
      title: 'JSON',
      children: [
        DemoRow(
          title: '对象 → JSON 字符串',
          expr: "JsonUtils.encodeObj({'name':'cutils','version':1})",
          result: encoded,
        ),
        DemoRow(
          title: 'JSON 字符串 → 对象（fromJson + fromMap）',
          expr: 'JsonUtils.fromJson<_DemoUser>(str, _DemoUser.fromMap)',
          result: parsed.toString(),
        ),
        DemoRow(
          title: 'JSON 字符串 → Map',
          expr: "JsonUtils.toMap('{\"name\":\"cutils\",\"version\":1}')",
          result: asMap.toString(),
        ),
        DemoRow(
          title: '日志输出 JSON（logJson → logger.i，输出见控制台）',
          expr: 'JsonUtils.logJson({...}, prettyPrint: true)',
          result: '调用后由 logger.i 打印到控制台',
        ),
      ],
    );
  }
}

/// 演示用模型：配合 [JsonUtils.fromJson] 的 fromMap 契约。
class _DemoUser {
  final String name;
  final int version;

  _DemoUser({required this.name, required this.version});

  factory _DemoUser.fromMap(Map<String, dynamic> map) => _DemoUser(
        name: map['name'] as String,
        version: map['version'] as int,
      );

  @override
  String toString() => '$name / v$version';
}
