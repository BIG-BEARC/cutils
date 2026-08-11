/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志条目
library;

/// 日志级别
enum LogLevel {
  verbose, // 详细日志
  debug, // 调试日志
  info, // 信息日志
  warning, // 警告日志
  error, // 错误日志
  fatal, // 致命错误
}

/// 日志来源
enum LogSource {
  debugPrint, // Flutter debugPrint
  console, // 控制台输出
  file, // 文件日志
  exception, // 异常日志
  network, // 网络日志
  custom, // 自定义日志
}

/// 日志条目
class LogEntry {
  /// 日志级别
  final LogLevel level;

  /// 日志内容
  final String message;

  /// 日志标签/分类
  final String tag;

  /// 日志来源
  final LogSource source;

  /// 时间戳
  final DateTime timestamp;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 错误对象
  final Object? error;

  /// 额外数据
  final Map<String, dynamic>? extra;

  /// 线程ID（如果有）
  final String? threadId;

  LogEntry({
    required this.level,
    required this.message,
    this.tag = 'default',
    this.source = LogSource.custom,
    DateTime? timestamp,
    this.stackTrace,
    this.error,
    Map<String, dynamic>? extra,
    this.threadId,
  })  : extra = extra == null ? null : Map<String, dynamic>.unmodifiable(extra),
        timestamp = timestamp ?? DateTime.now();

  /// 转换为字符串
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}]');
    buffer.write('[$level]');
    buffer.write('[$tag]');
    buffer.write('[$source]');
    if (threadId != null) {
      buffer.write('[$threadId]');
    }
    buffer.write(' $message');
    if (error != null) {
      buffer.write('\nError: $error');
    }
    if (stackTrace != null) {
      buffer.write('\nStackTrace: $stackTrace');
    }
    final extraMap = extra;
    if (extraMap != null && extraMap.isNotEmpty) {
      buffer.write('\nExtra: $extraMap');
    }
    return buffer.toString();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'source': source.name,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace?.toString(),
      'error': error?.toString(),
      'extra': extra,
      'threadId': threadId,
    };
  }

  /// 从JSON创建
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] ?? '',
      tag: json['tag'] ?? 'default',
      source: LogSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => LogSource.custom,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      stackTrace: (json['stackTrace'] as String?) != null
          ? StackTrace.fromString(json['stackTrace'] as String)
          : null,
      error: json['error'],
      extra: json['extra'] != null
          ? Map<String, dynamic>.unmodifiable(
              Map<String, dynamic>.from(json['extra'] as Map),
            )
          : null,
      threadId: json['threadId'],
    );
  }
}
