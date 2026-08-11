// Dart imports:
import 'dart:async';

// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 日志：薄封装 [logger]（release 静默）+ [LogCollectorHelper] 收集子系统。
///
/// 演示中先 [LogCollectorHelper.quickInitialize]（关闭文件存储便于演示），
/// 随后按钮触发各级别日志，输出同时落到控制台与收集器。
class LogDemo extends StatefulWidget {
  const LogDemo({super.key});

  @override
  State<LogDemo> createState() => _LogDemoState();
}

class _LogDemoState extends State<LogDemo> {
  final List<String> _lines = [];
  bool _collectorReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initCollector());
  }

  Future<void> _initCollector() async {
    try {
      await LogCollectorHelper.quickInitialize(enableFileStorage: false);
      if (!mounted) return;
      setState(() => _collectorReady = true);
    } catch (_) {
      // 演示环境忽略初始化错误。
    }
  }

  void _emit(String label, void Function() fn) {
    fn();
    if (!mounted) return;
    setState(() {
      _lines.insert(
          0, '${DateTime.now().toIso8601String().substring(11, 19)}  $label');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '日志',
      children: [
        const DemoRow(
          title: '薄封装 logger（release 下静默）',
          expr: "logger.i('msg', tag: 'demo')",
          result: '点击下方按钮输出到控制台',
        ),
        DemoRow(
          title: 'logCollector 状态',
          expr: 'LogCollectorHelper.quickInitialize(enableFileStorage: false)',
          result: _collectorReady ? '已初始化' : '初始化中…',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => _emit('logger.i',
                  () => logger.i('info 演示', tag: 'demo')),
              child: const Text('logger.i'),
            ),
            ElevatedButton(
              onPressed: () => _emit('logger.w',
                  () => logger.w('warn 演示', tag: 'demo')),
              child: const Text('logger.w'),
            ),
            ElevatedButton(
              onPressed: () => _emit('logger.e',
                  () => logger.e('error 演示', tag: 'demo')),
              child: const Text('logger.e'),
            ),
            ElevatedButton(
              onPressed: _collectorReady
                  ? () => _emit('LogCollectorHelper.info',
                      () => LogCollectorHelper.info('collector 演示'))
                  : null,
              child: const Text('collector.info'),
            ),
          ],
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _lines.isEmpty ? '（暂无输出，点上面按钮）' : _lines.join('\n'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
