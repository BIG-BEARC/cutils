// Dart imports:
import 'dart:async';

// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 存储：[spUtil] 单例需要先 `await spUtil.init()`，再做基本类型读写。
///
/// 演示中异步 init 后执行一次 putString → getString 往返并展示结果。
class StorageDemo extends StatefulWidget {
  const StorageDemo({super.key});

  @override
  State<StorageDemo> createState() => _StorageDemoState();
}

class _StorageDemoState extends State<StorageDemo> {
  String _status = '初始化中…';

  @override
  void initState() {
    super.initState();
    unawaited(_initAndDemo());
  }

  Future<void> _initAndDemo() async {
    try {
      await spUtil.init();
      await spUtil.putString('demo_key', '来自 cutils 的问候');
      final value = spUtil.getString('demo_key');
      final ready = spUtil.isInitialized();
      if (!mounted) return;
      setState(() {
        _status = 'init() OK → putString → getString\n'
            'demo_key = $value\n'
            'isInitialized() = $ready';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '初始化失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '存储（SharedPreferences）',
      children: [
        const DemoRow(
          title: 'API 说明',
          expr: 'spUtil.init() → spUtil.putString(k, v) → spUtil.getString(k)',
          result: '需先 init（异步）',
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status),
          ),
        ),
      ],
    );
  }
}
