// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'log_collector_config.dart';
import 'log_entry.dart';

/// * @Author: chuxiong
/// * @Created at: 2025/01/XX
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志存储
///
/// 内存（[Queue]，容量上限后队首丢弃）+ 文件（按日 JSON 行文件，超
/// [LogCollectorConfig.maxFileSize] 时轮转归档，超 [maxFileCount] 删最旧）。
/// 文件写入走持久化 [IOSink]，由定时器周期性 flush 而非每行强制刷盘。

class LogStorage {
  /// 当前存储配置。
  final LogCollectorConfig config;

  /// 内存存储（Queue：队首丢弃 O(1)，避免 List.removeAt(0) 的 O(n) 开销）。
  final Queue<LogEntry> _memoryStorage = Queue<LogEntry>();

  /// 存储目录
  Directory? _storageDir;

  /// 当前日志文件
  File? _currentLogFile;

  /// 当前日志文件的持久化写入 sink。
  ///
  /// 避免每条日志 `writeAsString(flush: true)` 触发的 open/write/flush/close
  /// 系统调用——写入缓冲区后由 [_flushTimer] 周期性 flush。
  IOSink? _fileSink;

  /// 当前日志文件的已知大小（字节），内存跟踪。
  ///
  /// 避免每次 store 调用 `exists()` + `length()` 两次 IO——仅在本类写入时
  /// 累加，rotate 时归零，[_initializeFileStorage] 时从磁盘读取初始值。
  int _currentFileSize = 0;

  /// 定期清理过期日志的计时器，[dispose] 时需取消以避免泄漏。
  Timer? _cleanupTimer;

  /// 定期 flush 文件 sink 的计时器，[dispose] 时需取消以避免泄漏。
  Timer? _flushTimer;

  LogStorage({required this.config});

  /// 仅供测试观察：periodic flush 回调被触发的次数。
  @visibleForTesting
  int periodicFlushCount = 0;

  /// 初始化存储
  Future<void> initialize() async {
    if (config.enableFileStorage) {
      await _initializeFileStorage();
    }

    if (config.autoCleanExpiredLogs) {
      _scheduleCleanup();
    }

    // 定时 flush：即使没有新日志到来，缓冲区中的日志也会在 flushInterval
    // 后落盘。文件存储关闭时回调为 no-op（_fileSink == null）。
    _scheduleFlush();
  }

  /// 初始化文件存储
  Future<void> _initializeFileStorage() async {
    final storagePath = config.storagePath ??
        path.join(
          (await getApplicationSupportDirectory()).path,
          'log_collector',
        );

    final dir = Directory(storagePath);
    _storageDir = dir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 创建当前日志文件
    final fileName = _getLogFileName(DateTime.now());
    final logFile = File(path.join(dir.path, fileName));
    _currentLogFile = logFile;

    // 如果文件已存在（例如今天早些时候写过），读取其大小作为初始值，
    // 避免 size tracking 与磁盘实际大小脱节导致轮转失效。
    if (await logFile.exists()) {
      _currentFileSize = await logFile.length();
    } else {
      _currentFileSize = 0;
    }
  }

  /// 获取日志文件名
  String _getLogFileName(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return 'log_$dateStr.json';
  }

  /// 存储日志
  Future<void> store(LogEntry entry) async {
    // 内存存储
    if (config.enableMemoryStorage) {
      _storeInMemory(entry);
    }

    // 文件存储
    if (config.enableFileStorage) {
      await _storeInFile(entry);
    }
  }

  /// 内存存储
  void _storeInMemory(LogEntry entry) {
    _memoryStorage.addLast(entry);

    // 限制内存中的日志数量（Queue.removeFirst O(1)）
    if (_memoryStorage.length > config.maxMemoryLogCount) {
      _memoryStorage.removeFirst();
    }
  }

  /// 惰性打开持久化 IOSink
  Future<void> _openSink() async {
    final file = _currentLogFile;
    if (_fileSink != null || file == null) {
      return;
    }
    _fileSink = file.openWrite(mode: FileMode.append);
  }

  /// 文件存储
  Future<void> _storeInFile(LogEntry entry) async {
    if (_currentLogFile == null) {
      return;
    }

    try {
      // 大小检查：基于内存跟踪的 [_currentFileSize]，不调用 exists()+length()。
      if (_currentFileSize >= config.maxFileSize) {
        await _rotateLogFile();
      }

      await _openSink();

      // 追加日志（不 flush——由 [_flushTimer] 周期性 flush）
      final jsonStr = jsonEncode(entry.toJson());
      final line = '$jsonStr\n';
      final sink = _fileSink;
      if (sink != null) {
        sink.write(line);
        _currentFileSize += utf8.encode(line).length;
      }
    } catch (e) {
      // 存储失败，记录到控制台
      debugPrint('LogStorage: Failed to store log: $e');
    }
  }

  /// 轮转日志文件
  Future<void> _rotateLogFile() async {
    final dir = _storageDir;
    if (dir == null) {
      return;
    }

    // 先 flush + close 旧 sink，确保缓冲数据落盘再 rename。
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;

    // 将当前文件重命名为归档文件（带时间戳后缀），确保新文件路径与之不同。
    // 否则按日期命名的"新"文件会与旧文件路径相同，轮转变为空操作，旧文件
    // 会被继续追加，永远超出 maxFileSize。
    final currentFile = _currentLogFile;
    if (currentFile != null && await currentFile.exists()) {
      final archiveName = 'log_${_archiveSuffix(DateTime.now())}.json';
      final archivePath = path.join(dir.path, archiveName);
      try {
        await currentFile.rename(archivePath);
      } catch (e) {
        debugPrint('LogStorage: Failed to archive log: $e');
      }
    }

    // 获取所有日志文件
    final logFiles = await _getLogFiles();

    // 删除超出数量限制的文件
    if (logFiles.length >= config.maxFileCount) {
      logFiles
          .sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      final filesToDelete =
          logFiles.take(logFiles.length - config.maxFileCount + 1);
      for (final file in filesToDelete) {
        await file.delete();
      }
    }

    // 创建新的日志文件
    final fileName = _getLogFileName(DateTime.now());
    _currentLogFile = File(path.join(dir.path, fileName));
    _currentFileSize = 0;
  }

  /// 归档文件名的时间戳后缀（`yyyy-MM-dd_HHMMss`）。
  String _archiveSuffix(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}'
        '-${two(date.month)}-${two(date.day)}'
        '_${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }

  /// 获取所有日志文件
  Future<List<File>> _getLogFiles() async {
    final dir = _storageDir;
    if (dir == null || !await dir.exists()) {
      return [];
    }

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        files.add(entity);
      }
    }
    return files;
  }

  /// 获取日志
  Future<List<LogEntry>> getLogs({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? level,
    String? tag,
  }) async {
    final logs = <LogEntry>[];

    // 从内存获取
    if (config.enableMemoryStorage) {
      logs.addAll(_memoryStorage);
    }

    // 从文件获取
    if (config.enableFileStorage) {
      final fileLogs = await _getLogsFromFiles(
        startTime: startTime,
        endTime: endTime,
        level: level,
        tag: tag,
      );
      logs.addAll(fileLogs);
    }

    // 过滤
    return logs.where((entry) {
      if (startTime != null && entry.timestamp.isBefore(startTime)) {
        return false;
      }
      if (endTime != null && entry.timestamp.isAfter(endTime)) {
        return false;
      }
      if (level != null && entry.level != level) {
        return false;
      }
      if (tag != null && entry.tag != tag) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 从文件流式获取日志
  ///
  /// 使用 [File.openRead] + [LineSplitter] 逐行流式解码，逐行短路过滤——
  /// 避免将整个文件读入内存再 split。内存占用仅与匹配结果集成正比。
  Future<List<LogEntry>> _getLogsFromFiles({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? level,
    String? tag,
  }) async {
    final logs = <LogEntry>[];
    final logFiles = await _getLogFiles();

    for (final file in logFiles) {
      try {
        final lineStream = file
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lineStream) {
          if (line.isEmpty) {
            continue;
          }
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final entry = LogEntry.fromJson(json);

            // 逐行短路过滤
            if (startTime != null && entry.timestamp.isBefore(startTime)) {
              continue;
            }
            if (endTime != null && entry.timestamp.isAfter(endTime)) {
              continue;
            }
            if (level != null && entry.level != level) {
              continue;
            }
            if (tag != null && entry.tag != tag) {
              continue;
            }

            logs.add(entry);
          } catch (e) {
            // 跳过无效的JSON行
            continue;
          }
        }
      } catch (e) {
        // 跳过无法读取的文件
        continue;
      }
    }

    return logs;
  }

  /// 清空日志
  Future<void> clear() async {
    _memoryStorage.clear();

    // 关闭旧 sink 后再删除文件，避免文件被占用。
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;

    final dir = _storageDir;
    if (dir != null && await dir.exists()) {
      final logFiles = await _getLogFiles();
      for (final file in logFiles) {
        await file.delete();
      }
    }
    _currentFileSize = 0;

    // 重建当前日志文件引用，使后续 store 可继续写入。
    if (dir != null) {
      final fileName = _getLogFileName(DateTime.now());
      _currentLogFile = File(path.join(dir.path, fileName));
    }
  }

  /// 导出日志
  Future<File?> export({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? level,
    String? tag,
  }) async {
    final logs = await getLogs(
      startTime: startTime,
      endTime: endTime,
      level: level,
      tag: tag,
    );

    if (logs.isEmpty) {
      return null;
    }

    // 创建导出文件
    final tempDir = await getTemporaryDirectory();
    final exportFile = File(
      path.join(
        tempDir.path,
        'log_export_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    // 写入日志
    final jsonList = logs.map((e) => e.toJson()).toList();
    await exportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );

    return exportFile;
  }

  /// 清理过期日志
  Future<void> cleanupExpiredLogs() async {
    final dir = _storageDir;
    if (dir == null || !await dir.exists()) {
      return;
    }

    final cutoffDate =
        DateTime.now().subtract(Duration(days: config.retentionDays));
    final logFiles = await _getLogFiles();

    for (final file in logFiles) {
      if (file.lastModifiedSync().isBefore(cutoffDate)) {
        await file.delete();
      }
    }
  }

  /// 安排清理任务
  void _scheduleCleanup() {
    // 每天清理一次；保存 Timer 引用以便 [dispose] 取消，避免泄漏。
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(days: 1), (timer) {
      cleanupExpiredLogs();
    });
  }

  /// 安排定时 flush 任务
  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(config.flushInterval, (timer) {
      performPeriodicFlush();
    });
  }

  /// 周期性 flush 文件 sink。
  ///
  /// 拆分为独立方法以便测试观察触发次数（[periodicFlushCount]）。
  @visibleForTesting
  void performPeriodicFlush() {
    periodicFlushCount++;
    _fileSink?.flush();
  }

  /// 仅供测试：显式 flush 文件 sink，确保缓冲区内容落盘以便读取验证。
  @visibleForTesting
  Future<void> flushForTesting() async {
    await _fileSink?.flush();
  }

  /// 销毁存储
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    // flush + close sink，确保缓冲数据落盘。
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
    _memoryStorage.clear();
    _currentFileSize = 0;
    _currentLogFile = null;
    _storageDir = null;
  }
}
