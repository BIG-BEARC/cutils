/// Windows SP 备份恢复的 web / 无 `dart:io` 平台 no-op 实现。
///
/// 经 [SpUtils] 的条件 import 选用（`dart.library.io` 不可用时）；两个
/// 入口与 `sp_backup_io.dart` 同签名，全部 no-op——web 端
/// SharedPreferences 走 localStorage，不存在文件损坏问题。
library;

/// no-op：web 无文件系统，无备份动作。
Future<void> backupSpFile() async {}

/// no-op：web 无文件系统，无恢复动作。
Future<void> restoreSpFile() async {}
