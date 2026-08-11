import 'dart:developer' as developer;

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';

import 'log_entry.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志输出器接口

/// 日志输出器抽象基类。子类实现 [output] 将一条 [LogEntry] 投递到目标
/// （控制台 / 文件 / 网络）。可选实现 [initialize] / [dispose] 管理资源。
abstract class LogOutput {
  /// 输出一条日志条目。
  Future<void> output(LogEntry entry);

  /// 初始化输出器（如打开连接 / 文件）。默认空实现。
  Future<void> initialize() async {}

  /// 销毁输出器（如 flush / 关闭流）。默认空实现。
  Future<void> dispose() async {}
}

/// 控制台输出器：通过 `developer.log` 输出（避免被 debugPrint 拦截器再次捕获）。
class ConsoleLogOutput extends LogOutput {
  /// 是否带 ANSI 颜色（按级别着色）。
  final bool enableColor;

  ConsoleLogOutput({this.enableColor = true});

  @override
  Future<void> output(LogEntry entry) async {
    if (enableColor) {
      _printWithColor(entry);
    } else {
      // 使用 developer.log 而非 print，符合 CLAUDE.md 规范，
      // 且避免被 debugPrint 拦截器再次捕获造成噪音/递归。
      developer.log(entry.toString());
    }
  }

  void _printWithColor(LogEntry entry) {
    // 根据日志级别选择不同的颜色（在支持ANSI颜色的终端）
    final colorCode = _getColorCode(entry.level);
    developer.log('\x1B[${colorCode}m${entry.toString()}\x1B[0m');
  }

  int _getColorCode(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 90; // 灰色
      case LogLevel.debug:
        return 36; // 青色
      case LogLevel.info:
        return 32; // 绿色
      case LogLevel.warning:
        return 33; // 黄色
      case LogLevel.error:
        return 31; // 红色
      case LogLevel.fatal:
        return 35; // 紫色
    }
  }
}

/// 文件输出器（尚未实现——占位类）
///
/// ⚠️ 当前为 TODO 占位类，直接构造会抛出 [UnimplementedError]，避免被当作
/// 空操作（no-op）静默使用导致日志丢失。后续实现完成后移除此抛出。
class FileLogOutput extends LogOutput {
  /// 输出文件路径。
  final String filePath;

  /// 单文件最大字节数，超出则轮转。
  final int maxFileSize;

  /// 保留的文件数量上限。
  final int maxFileCount;

  FileLogOutput({
    required this.filePath,
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFileCount = 10,
  }) {
    throw UnimplementedError(
      'FileLogOutput 尚未实现，请勿直接实例化（当前为占位类，'
      'output 为空操作会导致日志静默丢失）。',
    );
  }

  @override
  Future<void> output(LogEntry entry) async {
    // TODO: 实现文件输出逻辑
    // 需要考虑文件大小限制、文件轮转等
  }

  @override
  Future<void> dispose() async {
    // TODO: 关闭文件流
  }
}

/// 网络输出器（尚未实现——占位类）
///
/// ⚠️ 参见 [FileLogOutput]——直接构造会抛出 [UnimplementedError]。
class NetworkLogOutput extends LogOutput {
  /// 上报端点 URL。
  final String endpoint;

  /// 自定义请求头。
  final Map<String, String>? headers;

  /// 请求超时时长。
  final Duration timeout;

  NetworkLogOutput({
    required this.endpoint,
    this.headers,
    this.timeout = const Duration(seconds: 30),
  }) {
    throw UnimplementedError(
      'NetworkLogOutput 尚未实现，请勿直接实例化（当前为占位类，'
      'output 为空操作会导致日志静默丢失）。',
    );
  }

  @override
  Future<void> output(LogEntry entry) async {
    // TODO: 实现网络输出逻辑
    // 可以使用dio发送HTTP请求
  }
}

/// 批量输出器
/// 将日志批量收集后统一输出，提高性能。
///
/// 包装一个 [delegate] 输出器，缓冲达到 [batchSize] 或距上次 flush 超过
/// [batchInterval] 时统一 flush。即使后续无新日志，定时器也会触发 flush，
/// 避免缓冲日志无限期等待。
class BatchLogOutput extends LogOutput {
  /// 实际承载输出的委托输出器。
  final LogOutput delegate;

  /// 单批最大条数，达到即 flush。
  final int batchSize;

  /// 定时 flush 的最长间隔。
  final Duration batchInterval;

  final List<LogEntry> _buffer = [];
  DateTime? _lastFlushTime;

  /// 定时 flush 计时器：当缓冲区有日志但未达到 [batchSize] 时，保证在
  /// [batchInterval] 后仍会触发 flush，避免流量停止后缓冲日志无限期等待。
  Timer? _flushTimer;

  BatchLogOutput({
    required this.delegate,
    this.batchSize = 100,
    this.batchInterval = const Duration(seconds: 5),
  });

  /// 如果尚无挂起的 flush 计时器，则启动一个 [batchInterval] 后触发的
  /// 单次 flush。
  void _armFlushTimer() {
    if (_flushTimer != null) {
      return;
    }
    _flushTimer = Timer(batchInterval, () {
      _flushTimer = null;
      flush();
    });
  }

  @override
  Future<void> output(LogEntry entry) async {
    _buffer.add(entry);

    final now = DateTime.now();
    final lastFlush = _lastFlushTime;
    final shouldFlush = _buffer.length >= batchSize ||
        (lastFlush != null && now.difference(lastFlush) >= batchInterval);

    if (shouldFlush) {
      await flush();
    } else {
      // 即使后续没有新日志到来，定时器也会在 batchInterval 后触发 flush。
      _armFlushTimer();
    }
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) {
      return;
    }

    // 取消挂起的定时器——本次 flush 已经负责清空缓冲区。
    _flushTimer?.cancel();
    _flushTimer = null;

    final entries = List<LogEntry>.from(_buffer);
    _buffer.clear();
    _lastFlushTime = DateTime.now();

    // 每条 delegate.output 独立 try/catch：单条失败不影响其它条目的输出，
    // 也不会因为一条异常中断整个 flush 循环。
    for (final entry in entries) {
      try {
        await delegate.output(entry);
      } catch (e) {
        debugPrint('BatchLogOutput: delegate.output error: $e');
      }
    }
  }

  @override
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
    await delegate.dispose();
  }
}
