// Flutter imports:
import 'package:flutter/foundation.dart';

import 'log_collector.dart';
import 'log_entry.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志拦截器接口

/// 日志拦截器抽象类
abstract class LogInterceptor {
  /// 日志收集器引用
  LogCollector? _collector;

  /// 是否已启动
  bool _isStarted = false;

  /// 启动拦截器
  Future<void> start(LogCollector collector) async {
    if (_isStarted) {
      return;
    }
    _collector = collector;
    await onStart();
    _isStarted = true;
  }

  /// 停止拦截器
  Future<void> stop() async {
    if (!_isStarted) {
      return;
    }
    await onStop();
    _collector = null;
    _isStarted = false;
  }

  /// 子类实现：启动时的操作
  Future<void> onStart();

  /// 子类实现：停止时的操作
  Future<void> onStop();

  /// 收集日志
  Future<void> collect(LogEntry entry) async {
    await _collector?.collect(entry);
  }

  /// 是否已启动
  bool get isStarted => _isStarted;
}

/// DebugPrint拦截器
class DebugPrintInterceptor extends LogInterceptor {
  DebugPrintCallback? _originalDebugPrint;

  @override
  Future<void> onStart() async {
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      // 调用原始debugPrint
      if (_originalDebugPrint != null) {
        _originalDebugPrint!(message, wrapWidth: wrapWidth);
      }

      // 收集日志
      if (message != null && message.isNotEmpty) {
        collect(LogEntry(
          level: LogLevel.debug,
          message: message,
          tag: 'debugPrint',
          source: LogSource.debugPrint,
        ));
      }
    };
  }

  @override
  Future<void> onStop() async {
    if (_originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }
  }
}

/// 异常拦截器
class ExceptionInterceptor extends LogInterceptor {
  @override
  Future<void> onStart() async {
    // Flutter异常处理
    FlutterError.onError = (FlutterErrorDetails details) {
      // 调用原始异常处理
      FlutterError.presentError(details);

      // 收集异常日志
      collect(LogEntry(
        level: LogLevel.error,
        message: details.exceptionAsString(),
        tag: 'flutter_error',
        source: LogSource.exception,
        stackTrace: details.stack,
        error: details.exception,
        extra: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      ));
    };

    // Dart异常处理
    PlatformDispatcher.instance.onError = (error, stack) {
      collect(LogEntry(
        level: LogLevel.fatal,
        message: error.toString(),
        tag: 'dart_error',
        source: LogSource.exception,
        stackTrace: stack,
        error: error,
      ));
      return true; // 返回true表示已处理
    };
  }

  @override
  Future<void> onStop() async {
    // 恢复默认异常处理
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = null;
  }
}

/// 文件日志监听拦截器
/// 监听指定目录下的日志文件变化
class FileLogInterceptor extends LogInterceptor {
  final String logDirectory;
  final List<String> filePatterns;

  FileLogInterceptor({
    required this.logDirectory,
    this.filePatterns = const ['*.log'],
  });

  @override
  Future<void> onStart() async {
    // TODO: 实现文件监听逻辑
    // 可以使用 path_provider 和 file 包来监听文件变化
  }

  @override
  Future<void> onStop() async {
    // TODO: 停止文件监听
  }
}
