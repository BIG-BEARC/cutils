// Flutter imports:
import 'package:flutter/material.dart';

import 'package:cutils/log_collector/log_collector.dart';
import 'package:cutils/log_collector/log_collector_config.dart';
import 'package:cutils/log_collector/log_collector_helper.dart';
import 'package:cutils/log_collector/log_entry.dart';
import 'package:cutils/log_collector/log_interceptor.dart';
import 'package:cutils/log_collector/log_output.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志收集模块使用示例

/// 示例1: 快速初始化（最简单的方式）
Future<void> example1QuickInitialize() async {
  await LogCollectorHelper.quickInitialize();

  // 现在所有的debugPrint和异常都会被自动收集
  debugPrint('这条日志会被自动收集');

  // 手动收集日志
  LogCollectorHelper.info('这是一条手动收集的日志');
}

/// 示例2: 自定义配置初始化
Future<void> example2CustomConfig() async {
  // 创建生产环境配置
  final config = LogCollectorConfig.production();

  // 创建输出器
  //
  // ⚠️ FileLogOutput / NetworkLogOutput 尚未实现（占位类，构造即抛
  // UnimplementedError），此处注释掉仅作签名演示，待后续版本实现。
  final outputs = [
    ConsoleLogOutput(enableColor: false), // 生产环境不使用颜色
    // FileLogOutput(
    //   filePath: '/path/to/logs',
    //   maxFileSize: 5 * 1024 * 1024, // 5MB
    //   maxFileCount: 20,
    // ),
  ];

  // 创建拦截器
  final interceptors = [
    ExceptionInterceptor(), // 只拦截异常，不拦截debugPrint
  ];

  // 初始化
  await logCollector.initialize(
    config: config,
    outputs: outputs,
    interceptors: interceptors,
  );
}

/// 示例3: 使用批量输出器（提高性能）
Future<void> example3BatchOutput() async {
  final config = LogCollectorConfig.defaultConfig();

  // 创建批量输出器（演示用 ConsoleLogOutput 作 delegate）
  //
  // ⚠️ NetworkLogOutput 尚未实现（占位类，构造即抛 UnimplementedError），
  // 实际场景中可自定义 LogOutput 子类作为批量 delegate，待后续版本实现。
  final batchedOutput = BatchLogOutput(
    delegate: ConsoleLogOutput(),
    batchSize: 50, // 每50条日志发送一次
    batchInterval: Duration(seconds: 10), // 或每10秒发送一次
  );

  final outputs = [
    ConsoleLogOutput(),
    batchedOutput,
  ];

  await logCollector.initialize(
    config: config,
    outputs: outputs,
    interceptors: [DebugPrintInterceptor(), ExceptionInterceptor()],
  );
}

/// 示例4: 查询和导出日志
Future<void> example4QueryAndExport() async {
  final collector = logCollector;

  // 查询最近24小时的错误日志
  final errorLogs = await collector.getAllLogs(
    startTime: DateTime.now().subtract(Duration(days: 1)),
    endTime: DateTime.now(),
    level: LogLevel.error,
  );

  print('找到 ${errorLogs.length} 条错误日志');

  // 导出所有警告和错误日志
  final exportFile = await collector.exportLogs(
    startTime: DateTime.now().subtract(Duration(days: 7)),
    level: LogLevel.warning,
  );

  if (exportFile != null) {
    print('日志已导出到: ${exportFile.path}');
  }
}

/// 示例5: 使用标签分类日志
Future<void> example5TaggedLogs() async {
  // 收集网络相关日志
  LogCollectorHelper.log(
    '网络请求开始',
    level: LogLevel.info,
    tag: 'network',
    extra: {
      'url': 'https://api.example.com/users',
      'method': 'GET',
    },
  );

  // 收集数据库相关日志
  LogCollectorHelper.log(
    '数据库查询完成',
    level: LogLevel.debug,
    tag: 'database',
    extra: {
      'table': 'users',
      'duration': 150, // 毫秒
    },
  );

  // 查询特定标签的日志
  final networkLogs = await logCollector.getAllLogs(
    tag: 'network',
  );

  print('网络日志数量: ${networkLogs.length}');
}

/// 示例6: 在Flutter应用中使用
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日志收集示例',
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeLogCollector();
  }

  Future<void> _initializeLogCollector() async {
    await LogCollectorHelper.quickInitialize(
      minLevel: LogLevel.debug,
      enableFileStorage: true,
      enableMemoryStorage: true,
      enableConsoleOutput: true,
      enableDebugPrintInterceptor: true,
      enableExceptionInterceptor: true,
    );

    LogCollectorHelper.info('应用启动', tag: 'app_lifecycle');
  }

  void _testLogging() {
    // 测试不同级别的日志
    LogCollectorHelper.debug('调试信息');
    LogCollectorHelper.info('普通信息');
    LogCollectorHelper.warning('警告信息');

    // 测试错误日志
    try {
      throw Exception('测试异常');
    } catch (e, stackTrace) {
      LogCollectorHelper.error(
        '捕获到异常',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _exportLogs() async {
    final exportFile = await logCollector.exportLogs();
    if (exportFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('日志已导出到: ${exportFile.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日志收集示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testLogging,
              child: const Text('测试日志收集'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exportLogs,
              child: const Text('导出日志'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    LogCollectorHelper.info('应用关闭', tag: 'app_lifecycle');
    super.dispose();
  }
}
