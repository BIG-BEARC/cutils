import 'log_collector.dart';
import 'log_collector_config.dart';
import 'log_entry.dart';
import 'log_interceptor.dart';
import 'log_output.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志收集器辅助类，提供便捷的初始化和使用方式

class LogCollectorHelper {
  static LogCollector? _instance;

  /// 获取日志收集器实例
  static LogCollector get instance {
    _instance ??= LogCollector();
    return _instance!;
  }

  /// 快速初始化（使用默认配置）
  static Future<void> quickInitialize({
    LogLevel minLevel = LogLevel.debug,
    bool enableFileStorage = true,
    bool enableMemoryStorage = true,
    bool enableConsoleOutput = true,
    bool enableDebugPrintInterceptor = true,
    bool enableExceptionInterceptor = true,
  }) async {
    final config = LogCollectorConfig(
      minLevel: minLevel,
      enableFileStorage: enableFileStorage,
      enableMemoryStorage: enableMemoryStorage,
    );

    final outputs = <LogOutput>[];
    if (enableConsoleOutput) {
      outputs.add(ConsoleLogOutput());
    }

    final interceptors = <LogInterceptor>[];
    if (enableDebugPrintInterceptor) {
      interceptors.add(DebugPrintInterceptor());
    }
    if (enableExceptionInterceptor) {
      interceptors.add(ExceptionInterceptor());
    }

    await instance.initialize(
      config: config,
      outputs: outputs,
      interceptors: interceptors,
    );
  }

  /// 手动收集日志
  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String tag = 'manual',
    Map<String, dynamic>? extra,
  }) async {
    await instance.collect(LogEntry(
      level: level,
      message: message,
      tag: tag,
      source: LogSource.custom,
      extra: extra,
    ));
  }

  /// 收集调试日志
  static Future<void> debug(String message, {String tag = 'debug'}) async {
    await log(message, level: LogLevel.debug, tag: tag);
  }

  /// 收集信息日志
  static Future<void> info(String message, {String tag = 'info'}) async {
    await log(message, level: LogLevel.info, tag: tag);
  }

  /// 收集警告日志
  static Future<void> warning(String message, {String tag = 'warning'}) async {
    await log(message, level: LogLevel.warning, tag: tag);
  }

  /// 收集错误日志
  static Future<void> error(
    String message, {
    String tag = 'error',
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await instance.collect(LogEntry(
      level: LogLevel.error,
      message: message,
      tag: tag,
      source: LogSource.custom,
      error: error,
      stackTrace: stackTrace,
    ));
  }

  /// 收集致命错误日志
  static Future<void> fatal(
    String message, {
    String tag = 'fatal',
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await instance.collect(LogEntry(
      level: LogLevel.fatal,
      message: message,
      tag: tag,
      source: LogSource.custom,
      error: error,
      stackTrace: stackTrace,
    ));
  }
}
