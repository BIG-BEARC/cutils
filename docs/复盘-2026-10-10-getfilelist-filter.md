# 复盘 2026-10-10 — getFileList「环境问题」定性被推翻

**日期**: 2026-10-10

**事件**: `flutter test` 的 A3 zipFiles 用例持续失败，报 `FileSystemException: .../T/com.logi.xlog.temp (OS Error: Is a directory, errno = 21)`。前一轮会话把它定性为「本机 Logitech 残留目录导致的环境问题」，记为 backlog（建议用户手删残留目录 + 建议改 `Directory.systemTemp.createTemp()`）。

**经过**: 本轮评审复检该缺点时追了完整调用链 `zipFiles → getFileList → listSync 过滤`（lib/file/file_utils.dart:589 → :542），发现过滤是 `path.contains('.log')` **子串匹配**且**不排除目录**——任何名字带 `.log` 的目录都会被 `File()` 包装后交给 `ZipFileEncoder.addFile`，打开目录即 errno 21。残留目录只是**触发器**，真实缺陷是过滤逻辑；同函数还有 `.changed`（ctime）当修改时间用，与 :541 注释「按修改时间」不符。

**修正**: `getFileList` / `deleteLog` 改后缀匹配 + `is! File` 排除目录链接 + `.modified` 判过期；测试桩目录从 systemTemp 根改为专用子目录 + tearDownAll 自清理。修后全量 +277 全绿（原 +274 -1）。

**教训**: 「换个环境就消失的失败」≠ 环境问题。环境只提供触发器，还必须回答「为什么这个触发器能打进来」——答不出就是产品缺陷。本例中「用户删掉残留目录」会让失败消失，但缺陷仍在等下一个 `*.log` 目录。

**【待蒸馏】**：`FileStat.changed` 是 ctime 不是 mtime——重命名 / 权限变更都会刷新它，过期判定与「按时间」语义必须用 `.modified`（实证：lib/file/file_utils.dart:574 修复处；test/file/file_utils_test.dart:220「judges expiry by mtime」回归用例，2026-10-10）

**【待蒸馏】**：测试桩目录禁止直接用 `Directory.systemTemp` 根——宿主机残留文件会漏进被测枚举域造成假失败；用带微秒戳的专用子目录 + tearDownAll 自清理（实证：test/file/file_utils_test.dart:26-33，2026-10-10）
