// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:cutils/log/log.dart';

// Windows 端 SharedPreferences 文件备份 / 恢复（`dart:io` 实现）。
//
// 背景：`shared_preferences_windows` 把数据落在
// `<getApplicationSupportDirectory>/shared_preferences.json`，文件损坏
// （写入中断 / 磁盘异常）会让 `SharedPreferences.getInstance()` 在
// json 解码处抛错，`SpUtils.init()` 从此持续失败。本模块在 init 成功后
// 备份该文件；init 失败时先校验备份有效性（合法 JSON 对象）再回写——
// **先校验后替换**，任何失败都保持现场不动、只记日志，绝不向上抛。
//
// 布局耦合说明：文件名 / 目录取自 shared_preferences_windows 2.4.1 的
// 默认实现（`fileName = 'shared_preferences'` + `.json` 后缀 +
// Application Support 目录）；该包若更改默认布局，此处需同步。
//
// web 不可用（`dart:io` 限制）；非 Windows 平台为 no-op——该文件布局
// 仅存在于 Windows 端。经 SpUtils 条件 import 挂载，测试可直接 import
// 本文件（VM 上 dart:io 可用）。

/// shared_preferences_windows 2.4.1 默认文件名（不含扩展名）。
const String _kSpFileName = 'shared_preferences';

/// 校验 [content] 是否为「合法 JSON 且顶层为对象」——回写现场前对备份
/// 内容的最低置信要求。
bool isValidSpJson(String content) {
  if (content.isEmpty) return false;
  try {
    return json.decode(content) is Map<String, dynamic>;
  } catch (_) {
    return false;
  }
}

/// 把 [livePath] 复制为 [backupPath]（覆盖旧备份）。
///
/// live 文件不存在（首次启动）时不创建备份；任何 IO 异常只记日志、
/// 不向上抛（备份失败不应影响 init 成功路径的返回值）。
Future<void> backupToFile({
  required String livePath,
  required String backupPath,
}) async {
  try {
    final live = File(livePath);
    if (!await live.exists()) return;
    await live.copy(backupPath);
    logger.i('SpBackup backed up sp file');
  } catch (e) {
    logger.e('SpBackup backup failed: $e');
  }
}

/// 用 [backupPath] 恢复 [livePath]：**先校验后替换**。
///
/// 仅当备份存在且通过 [isValidSpJson] 校验时才回写 live；备份无效 / 不
/// 存在 / 回写 IO 失败时保持 live 原样（失败保现场），只记日志、不向上抛。
/// 恢复成功后备份保留在原位——后续 init 重试成功时成功路径会再备份一次，
/// 备份即自然更新为恢复后的新鲜内容。
Future<void> restoreFromFile({
  required String livePath,
  required String backupPath,
}) async {
  try {
    final backup = File(backupPath);
    if (!await backup.exists()) return;
    final content = await backup.readAsString();
    if (!isValidSpJson(content)) {
      logger.e('SpBackup backup invalid, keep live file untouched');
      return;
    }
    await File(livePath).writeAsString(content);
    logger.i('SpBackup restored sp file from backup');
  } catch (e) {
    logger.e('SpBackup restore failed: $e');
  }
}

/// init 成功后的备份入口（[SpUtils] 调用）。非 Windows no-op。
@visibleForTesting
Future<void> backupSpFile() => _withSpPaths(backupToFile);

/// init 失败后的恢复入口（[SpUtils] 调用）。非 Windows no-op。
@visibleForTesting
Future<void> restoreSpFile() => _withSpPaths(restoreFromFile);

/// 定位 SP 文件与备份路径后执行 [action]；定位失败（无 / 目录不可得）
/// 视为 no-op。
Future<void> _withSpPaths(
  Future<void> Function({required String livePath, required String backupPath})
      action,
) async {
  if (!Platform.isWindows) return;
  String? dirPath;
  try {
    dirPath = (await getApplicationSupportDirectory()).path;
  } catch (e) {
    logger.e('SpBackup resolve support dir failed: $e');
    return;
  }
  final livePath = p.join(dirPath, '$_kSpFileName.json');
  await action(livePath: livePath, backupPath: '$livePath.bak');
}
