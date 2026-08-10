# cutils 高危 bug 修复 + 回归测试实现计划 (Plan 3 of 5)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development + superpowers:test-driven-development. 每项 = 先写失败回归测试 → 看它失败 → 最小修复 → 绿 → commit。

**Goal:** 修复 spec §6.1 全部高危 bug（崩溃/栈溢出/静默错结果/随机删文件/安全），每项配回归测试。

**Architecture:** 按 7 个模块波推进，每波独立可测、独立提交。每项遵循 red-green-refactor：测试先钉死"当前错误行为会失败、修复后期望行为通过"，再动实现。**不改公开签名**（Plan 2 已定），不改有状态单例契约。

**Tech Stack:** Dart 3.6+ / Flutter ≥3.3、`package:test`+`mocktail`、`FakeAsync`(计时类)、`package:decimal`。macOS（BSD sed `\b` 不生效，用 `[[:<:]]`/`[[:>:]]`）。

**参考:** [spec §6.1](../specs/2026-08-07-cutils-core-restructure-design.md)。基线：`dart analyze` = 56 info / 0 warning / 0 error；`flutter test` = 9/9。每波结束 gate = 0 error/0 warning、info ≤ 起点、全测试绿。

> 锚定：行号在 Plan 1/2 后已漂移，**以函数/方法名为准**。

---

## Wave A — file_utils（6 项）

| # | 锚(函数) | bug | 修复方向 | 回归测试 |
|---|---|---|---|---|
| A1 | `readBySink` | 立即 `return ""`，listen fire-and-forget，永远读不到内容 | `await for` 或 `Completer<String>` 等流结束 | 写临时文件→`readBySink`→断言返回文件内容（非空） |
| A2 | `cleanExpiredLog` | 用 `lastModified.millisecond`(0-999)比 epoch 毫秒→随机删 | `lastModified.millisecondsSinceEpoch` | 建目录：1 个旧文件(2 天前)+1 个新文件→调用→断言只删旧文件、新文件在 |
| A3 | `deleteFileData`/`zipFiles`/`cleanExpiredLog` 内 | `file.delete()`、`encoder.close()`、`Directory.list().forEach()` 的 Future 未 await | 全部 await（删除/压缩真正完成才返回） | zipFiles→断言产出 zip 存在且可被 archive 解析；deleteFileData→断言调用后文件确已删除（await 完成后再 stat） |
| A4 | `deleteLog` | 忽略 `saveDays` 参数，硬编码 `>3` | `differDays > saveDays` | 设 saveDays=10，造 5 天前文件→断言被保留；saveDays=2→断言被删 |
| A5 | `_getFile`(路径拼接) | `filePath`/`fileName` 直接用 `/` 拼→路径穿越 + Windows 不兼容 | `p.join` + 拒绝含 `..`/绝对路径的段 | 传 `../../etc/passwd` 风格名→断言抛 ArgumentError 或被拒（不逃逸） |
| A6 | `createFileFromBase64` | 非法 base64 抛裸 `FormatException` | try/catch 包装抛类型化异常（或返回 null） | 传 `"!!!notbase64!!!"`→断言抛指定异常类型（非裸 FormatException） |

Files: `lib/file/file_utils.dart`；测试 `test/file/file_utils_test.dart`（扩）。

## Wave B — log_collector（7 项）

| # | 锚 | bug | 修复 | 回归测试 |
|---|---|---|---|---|
| B1 | `ExceptionInterceptor.onStart`(FlutterError.onError) | 内调 `presentError`→无限递归，首次错误栈溢出 | 保存原 handler 并直接调用，不走 `presentError` | 模拟 `FlutterError.onError` 触发→断言不抛 StackOverflow、原 handler 被调用（用 fake 原 handler 计数） |
| B2 | `_rotateLogFile` | 轮转空操作（新文件同名日期） | 重命名当前文件(加时间戳后缀)再重指向 | 超过 maxFileSize→写→断言旧文件被改名(存在带后缀的归档)、新文件是另一个 |
| B3 | `_scheduleCleanup`(Timer.periodic) | 未存 Timer、dispose 不取消→永久触发+持有 this | 存 Timer 字段，dispose 中 cancel | 用 `FakeAsync`：dispose 后 advance 时间→断言清理回调不再触发 |
| B4 | `dispose` | 清 `_outputs` 前不调 `output.dispose()` | 循环 `await output.dispose()` 再清 | 用 fake output 记录 dispose 调用→logCollector.dispose()→断言每个 output.dispose 被调 |
| B5 | `_logQueue`/collect | 无上限→高速日志+慢 IO 内存无限增长 | `maxQueueSize` 上限，满则丢弃/采样计数 | 灌入 > maxQueueSize 条（output 用慢 mock）→断言队列不超上限、丢弃有计数 |
| B6 | `initialize` | 双重初始化竞态(await 期间 `_isInitialized` 仍 false) | 同步置 `_isInitializing` 或 Completer | 并发两次 initialize→断言 storage 只 init 一次 |
| B7 | `ConsoleLogOutput.output` | 用 `print()`（违 CLAUDE.md + 被 debugPrint 拦截器捕获） | 改 `debugPrint`/`developer.log` | 捕获输出→断言不通过 `print`（可用 `print` mock/override 验证未被调用） |

Files: `lib/log_collector/{log_interceptor,log_storage,log_collector,log_output}.dart`；测试 `test/log_collector/`（新建）。

## Wave C — regex（4 项）

| # | 锚 | bug | 修复 | 回归测试 |
|---|---|---|---|---|
| C1 | `REGEX_INTEGER`/`REGEX_FLOAT` 等常量 | `^...\|...$` 未括号→`REGEX_INTEGER.hasMatch("123abc")`=true | `^(?:...\|0)$` 包裹所有数值正则 | 断言 `isInteger("123abc")`=false、`isInteger("0")`=true、`isFloat("1.23")`=true |
| C2 | 身份证正则 `[0|1|2]` | 字符类把 `\|`当字面量 | `[012]` | （并入 C1 测试）正则仅匹配 0/1/2，不匹配 `\|` |
| C3 | `isIdCard`(尾号校验) | 小写 `x` 被判无效 | `input[17].toUpperCase()` | 合法身份证尾号小写 x→断言 isIdCard=true |
| C4 | `REGEX_EMAIL`/`isEmail` | 嵌套量词 ReDoS | 换非回溯 `^[^\s@]+@[^\s@]+\.[^\s@]+$`+长度上限 | 长串 `"a.a.a…a"`(无@,50+ 段)→断言 <100ms 返回 false（不卡死）；正常邮箱→true |

Files: `lib/regex/{regex_constants,regex_utils}.dart`；测试 `test/regex/`（新建）。⚠️ C1/C4 改常量语义=破坏性（spec D5），CHANGELOG 记录。

## Wave D — system + net（5 项）

| # | 锚 | bug | 修复 | 回归测试 |
|---|---|---|---|---|
| D1 | `winUniqueIdentifier` | 混入 `DateTime.now()`→每次变 | 仅拼接稳定硬件 ID | 调两次→断言返回相同（mock 稳定硬件字段） |
| D2 | `closeKeyBoard` | 副作用藏状态栏/导航栏(`SystemUiMode.immersive`) | 移除该副作用；系统 UI 切换独立方法 | 调用→断言未触发 immersive 模式（mock SystemChrome 或检查无 setEnabledSystemUIMode 调用） |
| D3 | `navigationBarHeight` | `(padding.bottom-padding.top)/dpr` 算错 | `padding.bottom/dpr` | 构造 padding(bottom=48,top=24,dpr=3)→断言=16.0 |
| D4 | `NetUtil.isAvailable`(Windows) | `Platform.isWindows → return true` 当永远在线 | 走相同连通性检测 | mock Windows 下 connectivity=none→断言 false（不再硬编码 true） |
| D5 | `NetUtil`(结果聚合) | 只取 `result[0]`、蓝牙当断网 | 遍历"任一非 none"=在线；蓝牙视为在线或文档 | mock [wifi,vpn]→断言在线；mock [bluetooth]→断言在线（按决议） |

Files: `lib/system/{device_info_util,keyboard_util,system_utils}.dart`、`lib/net/net_util.dart`；测试 `test/system/`、`test/net/`。

## Wave E — num + money + double_ext（4 项）

| # | 锚 | bug | 修复 | 回归测试 |
|---|---|---|---|---|
| E1 | `addNum`/`subNum`/`mulNum`(`*Num`) | 大数科学计数法→静默 `?? 0.0` | 禁止 `?? 0.0` 兜底；解析失败抛或返回 null（spec D2 决议：规范型=Decimal） | 传入 `1e20` 级输入→断言不静默返回 0.0（抛或非零） |
| E2 | `divideDec`/`divideDecString` | `1/3` 非终止小数抛 StateError | `toDecimal(scaleOnInfinitePrecision: 20)` | `divideDec(1,3)`→断言不抛、返回有限 Decimal |
| E3 | `changeF2Y`(money_utils) | `int.parse(amountStr)` 空/非法/溢出抛 | `int.tryParse`+明确异常或默认 | `changeF2Y("")`/`changeF2Y("abc")`→断言抛指定异常或返回默认，不裸 FormatException |
| E4 | `thousandSeparated`(double_ext) | 负数→`-,100.00` | 先剥离符号格式化绝对值再补回 | `(-1000.0).thousandSeparated()`→断言 `"-1,000.00"`（负号在前、不当成数位） |

Files: `lib/num/{num_utils,money_utils}.dart`、`lib/ext/double_ext.dart`；测试 `test/num/`、`test/ext/`。

## Wave F — date + timer（4 项）

| # | 锚 | bug | 修复 | 回归测试 |
|---|---|---|---|---|
| F1 | `_comFormat`(SSS) | ms<100 只出 2 位 | `padLeft(3,'0')` | `formatDate(ms=5,'SSS')`→`"005"`；ms=50→`"050"`；ms=123→`"123"` |
| F2 | `isToday`(locMs 分支) | 忽略 `isUtc`→跨时区跨日错 | `getDateTimeByMs(locMs, isUtc: isUtc)` | UTC 边界用例：传 isUtc:true + 接近午夜的 locMs→断言与同 zone 比较一致 |
| F3 | `startCountDown`(timer_util) | 每次 tick 递减→漂移 | 一次性记 endTime，每 tick 算 `endTime.difference(now)` | `FakeAsync`：推进墙钟→断言剩余时间与墙钟一致（不漂移） |
| F4 | `startCountDown`/`cancel` | `Future.delayed` 不被 cancel 取消→重启串台 | 存 future 字段，cancel 中取消 | `FakeAsync`：start→cancel→再 start→推进→断言无 stale 回调触发 |

Files: `lib/datetime/date_utils.dart`、`lib/time-derived`(`lib/datetime/timer_util.dart`)；测试扩 `test/datetime/`、新建 `test/datetime/timer_util_test.dart`（FakeAsync）。

## Wave G — crypto + ui + sp（4 项）

| # | 锚 | bug | 修复 | 回归测试 |
|---|---|---|---|---|
| G1 | `encodeMd5File` | `readAsStringSync` 读二进制→hash 坏 | `md5.bind(file.openRead()).last`（流式字节） | 二进制文件→断言 `encodeMd5File`== 独立 `md5.convert(bytes)`；非 ASCII 文本→同 |
| G2 | `xorCode` | 无校验、代理对破坏往返 | 校验输入(整数列表)、全程 `List<int>`+base64 原始字节 | `xorBase64Encode`→`xorBase64Decode` 往返→断言还原（含会落到代理对范围的输入）；非法 key→抛 |
| G3 | `calculateTextHeight/Width`(ui/calculate_utils) | TextPainter 从不 dispose→原生泄漏 | `try/finally` + `painter.dispose()` | widget test 调用→不抛；可选：检查无 leak 警告 |
| G4 | sp_util getters | 把 value 打进 info 日志→PII/token 泄露 | 仅记 key，或 debug 开关控制 | setString('token','secret')→捕获日志→断言日志不含 'secret' |

Files: `lib/crypto/crypto_utils.dart`、`lib/ui/calculate_utils.dart`、`lib/storage/sp_util.dart`；测试 `test/crypto/`、`test/ui/`、扩 `test/storage/`。

---

## 执行约束（每波）
1. 每项先写失败回归测试，跑→见 FAIL（锁定 bug）。
2. 最小修复，跑→GREEN。
3. `dart analyze`（0 error/0 warning，info ≤ 波起点）+ `flutter test` 全绿。
4. 一波结束 commit（message 注明波+项；不含 CLAUDE.md 除非它本就干净）。
5. **不改公开签名**、不动 7 个有状态单例契约、不修中/低危（Plan 4）。
6. C1/C4 改正则语义=破坏性：本波 commit message + 最终 CHANGELOG 记 before/after（spec D5）。

## 完成标准
- [ ] §6.1 全部 26 项高危修复，每项有回归测试。
- [ ] `dart analyze` 0 error/0 warning；`flutter test` 全绿（测试数显著增加）。
- [ ] 7 波各一提交（或拆细），历史清晰。
- [ ] CHANGELOG 记破坏性正则语义变更（C1/C4）。

## 不在 Plan 3
中/低危（Plan 4）、dartdoc/全量单测（Plan 4）、example/README（Plan 5）、迁移 cashier（Plan 5）。
