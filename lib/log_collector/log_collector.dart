// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

import 'log_collector_config.dart';
import 'log_entry.dart';
import 'log_interceptor.dart';
import 'log_output.dart';
import 'log_storage.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 通用日志收集模块
///
/// 该模块不修改现有代码，通过拦截和监听的方式收集日志
final logCollector = LogCollector();

class LogCollector {
  LogCollector._internal();

  factory LogCollector() {
    return _instance;
  }

  static final LogCollector _instance = LogCollector._internal();

  /// 日志收集配置
  LogCollectorConfig? _config;

  /// 日志存储
  LogStorage? _storage;

  /// 日志输出器列表
  final List<LogOutput> _outputs = [];

  /// 日志拦截器列表
  final List<LogInterceptor> _interceptors = [];

  /// 日志队列
  final Queue<LogEntry> _logQueue = Queue<LogEntry>();

  /// 是否正在处理日志
  bool _isProcessing = false;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 进行中的初始化 Future，用于消除并发 initialize 的竞态。
  Future<void>? _initFuture;

  /// 初始化日志收集器
  /// [config] 日志收集配置
  /// [outputs] 日志输出器列表
  /// [interceptors] 日志拦截器列表
  Future<void> initialize({
    required LogCollectorConfig config,
    List<LogOutput>? outputs,
    List<LogInterceptor>? interceptors,
  }) async {
    if (_isInitialized) {
      return;
    }
    // 同步地缓存进行中的初始化 Future，确保并发调用者复用同一次初始化，
    // 而不是双双穿过 `_isInitialized == false` 判断导致重复初始化。
    return _initFuture ??= _initializeInternal(
      config: config,
      outputs: outputs,
      interceptors: interceptors,
    );
  }

  Future<void> _initializeInternal({
    required LogCollectorConfig config,
    List<LogOutput>? outputs,
    List<LogInterceptor>? interceptors,
  }) async {
    try {
      _config = config;
      _storage = LogStorage(config: config);

      // 添加默认输出器
      if (outputs != null && outputs.isNotEmpty) {
        _outputs.addAll(outputs);
      }

      // 添加默认拦截器
      if (interceptors != null && interceptors.isNotEmpty) {
        _interceptors.addAll(interceptors);
      }

      // 初始化存储
      await _storage?.initialize();

      // 启动拦截器
      for (final interceptor in _interceptors) {
        await interceptor.start(this);
      }

      _isInitialized = true;
    } finally {
      // 允许 dispose 后再次初始化；若初始化抛错也允许重试。
      _initFuture = null;
    }
  }

  /// 收集日志
  /// [entry] 日志条目
  Future<void> collect(LogEntry entry) async {
    final config = _config;
    if (!_isInitialized || config == null) {
      return;
    }

    // 检查日志级别过滤
    if (entry.level.index < config.minLevel.index) {
      return;
    }

    // 检查标签过滤
    if (config.filterTags.isNotEmpty &&
        !config.filterTags.contains(entry.tag)) {
      return;
    }

    // 队列上限：当输出过慢时，丢弃新到的日志，避免内存无限增长。
    if (_logQueue.length >= config.maxQueueSize) {
      return;
    }

    // 添加到队列
    _logQueue.add(entry);

    // 异步处理日志
    _processLogQueue();
  }

  /// 处理日志队列
  Future<void> _processLogQueue() async {
    if (_isProcessing || _logQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    try {
      while (_logQueue.isNotEmpty) {
        final entry = _logQueue.removeFirst();

        // 存储日志：即使存储抛出异常也不能中断队列的排空——否则后续条目
        // 永远留在队列中无法输出。
        try {
          await _storage?.store(entry);
        } catch (e) {
          debugPrint('LogCollector: Storage error: $e');
        }

        // 输出日志：遍历快照，避免 output.output() 内部调用 addOutput /
        // removeOutput 触发 ConcurrentModificationError。
        for (final output in List<LogOutput>.of(_outputs)) {
          try {
            await output.output(entry);
          } catch (e) {
            debugPrint('LogCollector: Output error: $e');
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 添加输出器
  void addOutput(LogOutput output) {
    _outputs.add(output);
  }

  /// 移除输出器
  void removeOutput(LogOutput output) {
    _outputs.remove(output);
  }

  /// 添加拦截器
  void addInterceptor(LogInterceptor interceptor) {
    _interceptors.add(interceptor);
    interceptor.start(this);
  }

  /// 移除拦截器
  void removeInterceptor(LogInterceptor interceptor) {
    _interceptors.remove(interceptor);
    interceptor.stop();
  }

  /// 获取所有日志
  Future<List<LogEntry>> getAllLogs({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? level,
    String? tag,
  }) async {
    return await _storage?.getLogs(
          startTime: startTime,
          endTime: endTime,
          level: level,
          tag: tag,
        ) ??
        [];
  }

  /// 清空日志
  Future<void> clearLogs() async {
    await _storage?.clear();
  }

  /// 导出日志
  Future<File?> exportLogs({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? level,
    String? tag,
  }) async {
    return await _storage?.export(
      startTime: startTime,
      endTime: endTime,
      level: level,
      tag: tag,
    );
  }

  /// 销毁日志收集器
  Future<void> dispose() async {
    // 停止拦截器
    for (final interceptor in _interceptors) {
      await interceptor.stop();
    }

    // 处理剩余的日志
    await _processLogQueue();

    // 释放每个输出器（例如 BatchLogOutput.flush）。
    // 拷贝一份再遍历，避免输出器在 dispose 过程中修改 _outputs。
    for (final output in List<LogOutput>.of(_outputs)) {
      try {
        await output.dispose();
      } catch (e) {
        debugPrint('LogCollector: Output dispose error: $e');
      }
    }

    // 清理资源
    _outputs.clear();
    _interceptors.clear();
    _logQueue.clear();

    await _storage?.dispose();
    _storage = null;
    _config = null;
    _isInitialized = false;
  }

  /// 获取当前配置
  LogCollectorConfig? get config => _config;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 当前待处理的日志队列长度
  int get pendingLogCount => _logQueue.length;

  /// 仅供测试注入 [LogStorage] 子类（例如抛出异常的存储）。
  @visibleForTesting
  set storageForTesting(LogStorage? value) {
    _storage = value;
  }
}
