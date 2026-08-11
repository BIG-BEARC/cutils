# cutils 中/低危修复 + dartdoc 实现计划 (Plan 4 of 5)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development + test-driven-development。每波 TDD（中危项）/ 机械清理（低危项）。

**Goal:** 修复 spec §6.2 全部中危 + §6.3 低危清理，并为公开 API 补 dartdoc。

**Architecture:** 5 波，每波独立可测、独立提交。中危项走 red-green（回归测试）；低危项机械清理（analyze 保持 0 warning）；dartdoc 一波覆盖。**不改公开签名**（已由 Plan 1-3 定），不引入新的破坏性语义。

**Tech Stack:** Dart 3.6+/Flutter ≥3.3、`package:test`+`mocktail`+`FakeAsync`。macOS（BSD sed `\b` 不生效）。

**参考:** [spec §6.2 / §6.3](../specs/2026-08-07-cutils-core-restructure-design.md)。基线：`dart analyze` = 54 info / 0 warning / 0 error；`flutter test` = 93/93 确定性。每波 gate = 0 error/0 warning、info ≤ 起点、全测试绿且确定性。

> 锚定：行号已漂移，**以函数/方法名为准**。

---

## Wave A — 子系统健壮性（log_collector / storage / json）

中危项（TDD）：
- **log_storage** `_memoryStorage.removeAt(0)` O(n) → 用 `Queue`（移除 front O(1)）；每条 `exists`+`length` 两次 IO → 内存记 `_currentFileSize`；每条 `flush:true` → 定时批量 flush；`_getLogsFromFiles` 全文件读入 → 流式短路。
- **log_collector** `store` 无 try/catch（存储抛错致队列不排空）→ 包装；迭代 `_outputs` 与增删并发修改 → 迭代 `List.of(_outputs)` 快照；`interceptor.start` 未 await → await。
- **log_output** `BatchLogOutput` 无 Timer（无流量时缓冲无限等待）→ `Timer(batchInterval)` 定时 flush；`flush` 先清缓冲致 delegate 抛错丢剩余 → 逐条 try/catch；`FileLogOutput`/`NetworkLogOutput` TODO 桩却收参 → 标 `abstract`/未实现文档（spec D6：先 abstract）。
- **log_interceptor** onStop 不还原原 handler → 保存并 restore；`FileLogInterceptor` 全 TODO 死代码 → 删除。
- **event_bus** 无 dispose/destroy，遗忘取消的订阅泄漏 → 注册集 + `dispose()` 关 controller。
- **storage/sp_util** `init` 竞态 → 存在途 Future 单次化（Completer）；`putObject` 名不副实 → 改名 `putJsonable` 或收 `toJson`；`.where().cast<String>()` → `.whereType<String>()`。
- **json** `encodeObjectList` 空列表返回 null → `"[]"`；`json.decode` 大整数精度丢失 → 文档化（或 reviver）；`printJson` 命名踩禁词 → `logJson`。

Files: `lib/log_collector/*`、`lib/storage/sp_util.dart`、`lib/json/json_utils.dart`。Tests: 扩 `test/log_collector/`、`test/storage/`、`test/json/`。

## Wave B — 纯逻辑工具（num / money / ext）

中危项（TDD）：
- **num_utils** `*Num()` 经 `toString()` 中转 num 入参 → 文档化"按 toString 解析、仅字面量/小值安全"，或加重载收 Decimal/String（additive）。
- **money_utils** Decimal→double→toStringAsFixed 大额丢精度 → 直接由 Decimal 格式化；enum switch 有 default 失去穷尽 → 去 default、逐 case。
- **string_ext** `formatMoney` 大数科学计数法 → Decimal/toStringAsFixed；`moneyFormatWithUnit` 与 double_ext 重复且未声明单位(分) → 文档化/去重。
- **int_ext** `percentFormat` 文档示例用 0.25（int 扩展上不可能）→ 修文档；`this!*100` 溢出 → 文档化；`¥` 前加空格 → 去空格。
- **double_ext** `percentFormat` 不乘 100 而 int 版乘 100 → 统一（乘 100）。
- **object_ext** `isNullOrBlank` 把 0 当空 → 去 0 规则；`this is! bool` 死代码（bool 非 num 子类型）→ 删。

Files: `lib/num/*`、`lib/ext/{string_ext,int_ext,double_ext,object_ext}.dart`。Tests: 扩 `test/num/`、`test/ext/`。

## Wave C — 日期 / 网络 / 正则中危

中危项（TDD）：
- **date** `getYesterday` 减 24h（DST 错）→ 减一个日历日；`ms==0` 当"非今天"误伤 epoch 0 → 去 `==0` 判断、仅靠 null；跨时区比较未归一（isYesterday/isWeek/getWeekNumber）→ 归一同 zone；`nextMonth` 返回 int 而同类返回 DateTime → 统一。
- **data_formats** `static final` 字面量 → `const`；`MONTH_DAY` 全局可变 map → `const` 私有。
- **timeline** `ArgumentError.checkNotNull` 已废弃 → 删（null-safety 已保证）；用后缀字符串判方向 → enum；isUtc 未贯穿；未来日期走"今天"格式语义错 → 文档化。
- **timer** `updateTotalTime` 副作用重启 → 拆 `setTotalTime`+显式 start；缺 `dispose()` → 补并文档化（别名 cancel）。
- **regex** `isURL`/`isIP` 未锚定 → `^...$`；`isNumeric` 接受 `"123."` → 要点后必有数字；`isJSON` 语义不清 → 文档化。
- **regex_constants** 小写 `email`/`url`/文件扩展正则与 `REGEX_*` 重复且冲突、`.` 未转义、大小写敏感 → 选一套删另一套、`^.+\.(?:...)$`+`(?i)`（spec §6.2/6.3）。
- **net** switch 非穷尽（vpn/tethering/mixed 落 default 当 none）→ 逐 case；缓存不刷新不订阅 stream → 订阅 `onConnectivityChanged` 并 dispose；`checkConnectivity` 无 timeout → 加 timeout。

Files: `lib/datetime/*`、`lib/regex/*`、`lib/net/*`。Tests: 扩对应 test 目录。

## Wave D — 低危清理（机械，spec §6.3）

按文件批处理（保持 analyze 0 warning、不破行为）：
- 通用：去违规 `!`（改局部变量绑定）、字面量加 `const`、可变全局集合改 `const`/私有不可变、`== true` 死判断、`var`→`final`、单引号、行宽 ≤80、`dart format`。
- 重复 API 去重：`numUtils` 全局 vs factory（Plan 2 已消除）、`safeValue`/`defaultValue` 合并、`moneyFormatWithUnit` 两文件重复、两套 `percentFormat`（Wave B 统一）、`regex_constants` 的 `REGEX_*` 与小写常量两套（Wave C 选一套）。
- 死代码：`net/url_utils.dart` 空类（删或实现）、`ext/bool_ext.then` 误导命名、`abs_time_info.weeks` 未用、`log/log.dart` 六方法重复 → 收敛。
- 文档与实现不符：`day_format.dart` 阈值描述、`keyboard_util` isCapsLock、`time/*_info` 重复类共享基类。
- 命名：`deviceInfo` 全局/getter/局部三重遮蔽、`money_unit` 枚举 `SCREAMING_SNAKE`→camelCase、`foucusNode` 拼写、`"unKnow"`→`"unknown"`、`encryptUtils` 全局（Plan 2 已随转静态消除）。
- `log_entry.dart` `extra` 深不可变（copy）；`StackTrace.fromString` 先 `as String?`。

Files: 全 `lib/`。无新测试（机械清理），gate = analyze 不增 + 现有 93 测试仍绿。

## Wave E — dartdoc 公开 API

- 每个**公开类/方法/顶层函数/扩展**加 `///` 文档注释，含一行可运行示例（呼应 CLAUDE.md）。
- 修正 Wave D 发现的"文档与实现不符"。
- 优先级：先 num/ext/datetime/regex/json/crypto（纯函数，最常被引用），再 file/storage/net/system/ui/event/identifier/log。
- gate = analyze 0 warning（dartdoc 本身不产生 warning，但确保无新增）+ 93 测试绿。

---

## 执行约束（每波）
1. 中危项：失败回归测试 → 最小修复 → 绿。低危/dartdoc：机械改 + analyze 0 warning + 现有测试不破。
2. **测试必须确定性**（FakeAsync/Completer，无真实延迟）。
3. **不改公开签名**（additive `@visibleForTesting` helper 可）。
4. 一波结束 commit（message 注明波；不含 CLAUDE.md）。
5. 破坏性语义变更（如有）→ commit message 注明 + 留 Plan 5 CHANGELOG。

## 完成标准
- [ ] §6.2 中危全修（每项回归测试）；§6.3 低危清理完毕；公开 API dartdoc 覆盖。
- [ ] `dart analyze` 0 error/0 warning；`flutter test` 全绿且确定性。
- [ ] 5 波各一提交，历史清晰。

## 不在 Plan 4
example 演示页 + README + CHANGELOG + 迁移 cashier（Plan 5）。
