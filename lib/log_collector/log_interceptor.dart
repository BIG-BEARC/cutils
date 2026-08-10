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
  /// 启动前捕获的 [FlutterError.onError]，停止时恢复。
  void Function(FlutterErrorDetails)? _previousOnError;

  /// 启动前捕获的 [PlatformDispatcher.instance.onError]，停止时恢复。
  ///
  /// 注意：不能在 onStop 中直接置为 null——会丢弃宿主 App 已注册的处理器，
  /// 必须还原 onStart 时捕获的原值。
  bool Function(Object error, StackTrace stackTrace)? _previousPlatformOnError;

  @override
  Future<void> onStart() async {
    // 捕获前一个处理器，避免直接调用 [FlutterError.presentError]：
    // presentError 在部分 Flutter 版本中会再次派发到 FlutterError.onError，
    // 造成无限递归；同时确保原始处理器（如默认控制台输出）不会被覆盖丢失。
    _previousOnError = FlutterError.onError;
    // 同样捕获 PlatformDispatcher 的原处理器，停止时还原而非置 null。
    _previousPlatformOnError = PlatformDispatcher.instance.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // 直接调用前一个处理器，禁止通过 FlutterError.presentError 回派。
      _previousOnError?.call(details);

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
    // 恢复原始异常处理器（还原捕获的原值，而非置 null 丢弃宿主已注册的处理器）。
    FlutterError.onError = _previousOnError;
    _previousOnError = null;
    PlatformDispatcher.instance.onError = _previousPlatformOnError;
    _previousPlatformOnError = null;
  }
}
