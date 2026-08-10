// Dart imports:
import 'dart:async';
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

class LogStorage {
  final LogCollectorConfig config;

  /// 内存存储
  final List<LogEntry> _memoryStorage = [];

  /// 存储目录
  Directory? _storageDir;

  /// 当前日志文件
  File? _currentLogFile;

  /// 定期清理过期日志的计时器，[dispose] 时需取消以避免泄漏。
  Timer? _cleanupTimer;

  LogStorage({required this.config});

  /// 初始化存储
  Future<void> initialize() async {
    if (config.enableFileStorage) {
      await _initializeFileStorage();
    }

    if (config.autoCleanExpiredLogs) {
      _scheduleCleanup();
    }
  }

  /// 初始化文件存储
  Future<void> _initializeFileStorage() async {
    String storagePath;
    if (config.storagePath != null) {
      storagePath = config.storagePath!;
    } else {
      final appDir = await getApplicationSupportDirectory();
      storagePath = path.join(appDir.path, 'log_collector');
    }

    _storageDir = Directory(storagePath);
    if (!await _storageDir!.exists()) {
      await _storageDir!.create(recursive: true);
    }

    // 创建当前日志文件
    final fileName = _getLogFileName(DateTime.now());
    _currentLogFile = File(path.join(_storageDir!.path, fileName));
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
    _memoryStorage.add(entry);

    // 限制内存中的日志数量
    if (_memoryStorage.length > config.maxMemoryLogCount) {
      _memoryStorage.removeAt(0);
    }
  }

  /// 文件存储
  Future<void> _storeInFile(LogEntry entry) async {
    if (_currentLogFile == null) {
      return;
    }

    try {
      // 检查文件大小
      if (await _currentLogFile!.exists()) {
        final fileSize = await _currentLogFile!.length();
        if (fileSize >= config.maxFileSize) {
          await _rotateLogFile();
        }
      }

      // 追加日志
      final jsonStr = jsonEncode(entry.toJson());
      await _currentLogFile!.writeAsString(
        '$jsonStr\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // 存储失败，记录到内存
      debugPrint('LogStorage: Failed to store log: $e');
    }
  }

  /// 轮转日志文件
  Future<void> _rotateLogFile() async {
    if (_storageDir == null) {
      return;
    }

    // 先将当前文件重命名为归档文件（带时间戳后缀），确保新文件路径与之不同。
    // 否则按日期命名的"新"文件会与旧文件路径相同，轮转变为空操作，旧文件
    // 会被继续追加，永远超出 maxFileSize。
    if (_currentLogFile != null && await _currentLogFile!.exists()) {
      final archiveName = 'log_${_archiveSuffix(DateTime.now())}.json';
      final archivePath = path.join(_storageDir!.path, archiveName);
      try {
        await _currentLogFile!.rename(archivePath);
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
    _currentLogFile = File(path.join(_storageDir!.path, fileName));
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
    if (_storageDir == null || !await _storageDir!.exists()) {
      return [];
    }

    final files = <File>[];
    await for (final entity in _storageDir!.list()) {
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

  /// 从文件获取日志
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
        final content = await file.readAsString();
        final lines = content.split('\n').where((line) => line.isNotEmpty);

        for (final line in lines) {
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final entry = LogEntry.fromJson(json);

            // 简单过滤
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

    if (_storageDir != null && await _storageDir!.exists()) {
      final logFiles = await _getLogFiles();
      for (final file in logFiles) {
        await file.delete();
      }
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
    if (_storageDir == null || !await _storageDir!.exists()) {
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

  /// 销毁存储
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _memoryStorage.clear();
    _currentLogFile = null;
    _storageDir = null;
  }
}
