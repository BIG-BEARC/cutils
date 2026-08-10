import 'log_entry.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志收集器配置

class LogCollectorConfig {
  /// 最小日志级别
  final LogLevel minLevel;

  /// 日志存储目录
  final String? storagePath;

  /// 日志文件最大大小（字节）
  final int maxFileSize;

  /// 日志文件最大数量
  final int maxFileCount;

  /// 日志保留天数
  final int retentionDays;

  /// 是否启用文件存储
  final bool enableFileStorage;

  /// 是否启用内存存储
  final bool enableMemoryStorage;

  /// 内存中最大日志数量
  final int maxMemoryLogCount;

  /// 待处理日志队列的最大长度
  ///
  /// 当输出较慢时，超出此长度的入队请求会被丢弃，避免内存无限增长。
  final int maxQueueSize;

  /// 过滤的标签列表（空列表表示不过滤）
  final List<String> filterTags;

  /// 是否启用日志压缩
  final bool enableCompression;

  /// 日志格式模板
  final String? logFormat;

  /// 是否自动清理过期日志
  final bool autoCleanExpiredLogs;

  /// 文件 sink 的定时 flush 间隔
  ///
  /// 日志写入持久化 [IOSink] 后不立即 flush（避免每行强制刷盘），而是由此
  /// 定时器周期性 flush。即使流量停止，缓冲区中的日志也会在 [flushInterval]
  /// 后落盘。
  final Duration flushInterval;

  const LogCollectorConfig({
    this.minLevel = LogLevel.debug,
    this.storagePath,
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFileCount = 10,
    this.retentionDays = 7,
    this.enableFileStorage = true,
    this.enableMemoryStorage = true,
    this.maxMemoryLogCount = 1000,
    this.maxQueueSize = 1000,
    this.filterTags = const [],
    this.enableCompression = false,
    this.logFormat,
    this.autoCleanExpiredLogs = true,
    this.flushInterval = const Duration(seconds: 5),
  });

  /// 默认配置
  factory LogCollectorConfig.defaultConfig() {
    return const LogCollectorConfig();
  }

  /// 开发环境配置
  factory LogCollectorConfig.development() {
    return const LogCollectorConfig(
      minLevel: LogLevel.verbose,
      enableFileStorage: true,
      enableMemoryStorage: true,
      maxMemoryLogCount: 5000,
      retentionDays: 3,
    );
  }

  /// 生产环境配置
  factory LogCollectorConfig.production() {
    return const LogCollectorConfig(
      minLevel: LogLevel.warning,
      enableFileStorage: true,
      enableMemoryStorage: false,
      maxMemoryLogCount: 100,
      retentionDays: 30,
      autoCleanExpiredLogs: true,
    );
  }

  /// 复制配置
  LogCollectorConfig copyWith({
    LogLevel? minLevel,
    String? storagePath,
    int? maxFileSize,
    int? maxFileCount,
    int? retentionDays,
    bool? enableFileStorage,
    bool? enableMemoryStorage,
    int? maxMemoryLogCount,
    int? maxQueueSize,
    List<String>? filterTags,
    bool? enableCompression,
    String? logFormat,
    bool? autoCleanExpiredLogs,
    Duration? flushInterval,
  }) {
    return LogCollectorConfig(
      minLevel: minLevel ?? this.minLevel,
      storagePath: storagePath ?? this.storagePath,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxFileCount: maxFileCount ?? this.maxFileCount,
      retentionDays: retentionDays ?? this.retentionDays,
      enableFileStorage: enableFileStorage ?? this.enableFileStorage,
      enableMemoryStorage: enableMemoryStorage ?? this.enableMemoryStorage,
      maxMemoryLogCount: maxMemoryLogCount ?? this.maxMemoryLogCount,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
      filterTags: filterTags ?? this.filterTags,
      enableCompression: enableCompression ?? this.enableCompression,
      logFormat: logFormat ?? this.logFormat,
      autoCleanExpiredLogs: autoCleanExpiredLogs ?? this.autoCleanExpiredLogs,
      flushInterval: flushInterval ?? this.flushInterval,
    );
  }
}
