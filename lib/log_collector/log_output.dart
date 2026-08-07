import 'log_entry.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志输出器接口

/// 日志输出器抽象类
abstract class LogOutput {
  /// 输出日志
  Future<void> output(LogEntry entry);

  /// 初始化输出器
  Future<void> initialize() async {}

  /// 销毁输出器
  Future<void> dispose() async {}
}

/// 控制台输出器
class ConsoleLogOutput extends LogOutput {
  final bool enableColor;

  ConsoleLogOutput({this.enableColor = true});

  @override
  Future<void> output(LogEntry entry) async {
    if (enableColor) {
      _printWithColor(entry);
    } else {
      print(entry.toString());
    }
  }

  void _printWithColor(LogEntry entry) {
    // 根据日志级别选择不同的颜色（在支持ANSI颜色的终端）
    final colorCode = _getColorCode(entry.level);
    print('\x1B[${colorCode}m${entry.toString()}\x1B[0m');
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

/// 文件输出器
class FileLogOutput extends LogOutput {
  final String filePath;
  final int maxFileSize;
  final int maxFileCount;

  FileLogOutput({
    required this.filePath,
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFileCount = 10,
  });

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

/// 网络输出器
class NetworkLogOutput extends LogOutput {
  final String endpoint;
  final Map<String, String>? headers;
  final Duration timeout;

  NetworkLogOutput({
    required this.endpoint,
    this.headers,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<void> output(LogEntry entry) async {
    // TODO: 实现网络输出逻辑
    // 可以使用dio发送HTTP请求
  }
}

/// 批量输出器
/// 将日志批量收集后统一输出，提高性能
class BatchLogOutput extends LogOutput {
  final LogOutput delegate;
  final int batchSize;
  final Duration batchInterval;

  final List<LogEntry> _buffer = [];
  DateTime? _lastFlushTime;

  BatchLogOutput({
    required this.delegate,
    this.batchSize = 100,
    this.batchInterval = const Duration(seconds: 5),
  });

  @override
  Future<void> output(LogEntry entry) async {
    _buffer.add(entry);

    final now = DateTime.now();
    final shouldFlush = _buffer.length >= batchSize ||
        (_lastFlushTime != null &&
            now.difference(_lastFlushTime!) >= batchInterval);

    if (shouldFlush) {
      await flush();
    }
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) {
      return;
    }

    final entries = List<LogEntry>.from(_buffer);
    _buffer.clear();
    _lastFlushTime = DateTime.now();

    for (final entry in entries) {
      await delegate.output(entry);
    }
  }

  @override
  Future<void> dispose() async {
    await flush();
    await delegate.dispose();
  }
}
