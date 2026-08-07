# cutils 核心通用工具库 · 重构与质量提升设计

- **日期**: 2026-08-07
- **状态**: 评审修订 v1（2026-08-07）— §6 已逐条核实属实；契约/策略决议见 §11 D1–D7；内联修订记录见 §12
- **范围**: `cutils` 核心包（纯 Dart + Flutter 框架 + 通用平台插件）
- **不在本次范围**: 硬件相关（串口 / 电子秤 / 扫码 / 打印机）→ 后续独立子包 `cutils_pos`，参考 `saas-cashier` `master_windows` 分支

---

## 1. 目标

把 `cutils` 整理成一个**可发布、可信、精简**的通用 Flutter 工具库：

- **可信**: 修复全部已发现的实现层 bug（高/中/低），每个 bug 配回归测试。
- **精简**: 去死代码、去死依赖、去 plugin 脚手架；只保留通用平台插件。
- **清晰**: 模块边界合理、命名无 SDK 冲突、统一 API 风格、单一 barrel 导出。
- **可用**: 每个公开 API 有 dartdoc 示例；`example/` 提供按领域分组的可运行 demo。

受众标准按"未来可发布到 pub.dev"执行：稳定且有文档的公开 API、零死代码、避开与 Flutter SDK 同名。当前仍为自用，**本次允许破坏性改 import 路径与调用点**（主要消费者 `cashier` 同步迁移）。

---

## 2. 范围界定

### 本次纳入（`cutils` 核心）
所有平台无关工具 + 通用平台插件工具（见 §4 模块归属）。

### 本次排除（后续 `cutils_pos`）
- `scanner/scan_monitor`、`system/serial_util`（全注释）、电子秤（`rxdart`，当前死依赖）。
- 参考来源: `/Users/chuxiong/project/saas-cashier` `master_windows` 分支的 `lib/utils/serial_util.dart`、`lib/module/electronic_scale/`、`lib/module/scanner/`、`lib/pub/printer/`。注意 cashier 硬件大量依赖本地 `plugin/` 下的 path 插件（不可上 pub），`cutils_pos` 定位为内部共享包（path 依赖），**不**上 pub.dev。

---

## 3. 目标包结构

`cutils` 由 **plugin 包降级为普通包**（删除 `flutter.plugin` 段、android/ios 原生、method_channel、platform_interface、`Cutils` 类）。

```
lib/
  cutils.dart                     # 新增: 顶层 barrel，re-export 全部核心
  ext/                            # 保留(string/int/double/bool/object/widget + ext_fun barrel)
  num/                            # 保留(num_utils/money_utils/money_unit)
  datetime/                       # ★ 合并 date/ + time/
  regex/  json/  file/  net/      # 保留
  crypto/                         # ★ encrypt/ 改名(实际用 crypto 包)
  storage/                        # ★ sp/ 改名
  system/                         # 保留(device_info/package_info/keyboard/system_utils)
  ui/                             # ★ 新: calculate_utils + image_utils
  event/                          # ★ utils/event_bus_util
  identifier/                     # ★ utils/uuid_utils + random_utils
  log/                            # 保留(简单 logger)
  log_collector/                  # 保留(独立子系统，自带 export)
```

### 结构性改动

| # | 改动 | 原因 |
|---|------|------|
| S1 | 合并 `date/`+`time/` → `datetime/` | time 已依赖 date，本就耦合 |
| S2 | `DateUtils` → `DateTimeUtils` | ⚠️ 与 Flutter SDK `DateUtils` 撞名 |
| S3 | 解散 `utils/` grab-bag | event_bus→`event/`、image→`ui/`、random+uuid→`identifier/` |
| S4 | `text/calculate_utils` → `ui/` | TextPainter 测量属 UI |
| S5 | `text/text_utils` 字符串谓词并入 `ext/string_ext`，删除 `text_utils`；**非谓词方法**（`reverse`→用 runes 的扩展、`abbreviate`、`formatDoubleComma3`）一并迁入 `ext/string_ext` 作扩展 | 与 string_ext 重复；迁移需改 cashier 调用点 |
| S6 | `encrypt/` → `crypto/`；**类 `EncryptUtils` 一并改 `CryptoUtils`**（半改名比不改更乱） | 用的是 `crypto` 包，"encrypt" 是另一个包，误导 |
| S7 | `sp/` → `storage/`；**全局单例 `sp` 新名建议 `spStorage`**（见 §11 D3，避免与目录/类歧义） | "sp" 是实现细节缩写，`storage` 自解释 |
| S8 | 删 `scanner/`、注释版 `serial_util` | 硬件，延期 |
| S9 | 删 plugin 脚手架(`Cutils`/method_channel/platform_interface/android/ios) | 仅 `getPlatformVersion`，无价值 |
| S10 | `lib/log_collector/example/usage_example.dart` 移出 `lib/` → `example/` | 不该随包发布/编译 |

---

## 4. API 约定

| 类型 | 形式 | 说明 |
|------|------|------|
| 类型相关 | **扩展** | `'x'.isEmail`、`42.toPx`、`widget.glow(...)` |
| 跨类型·无状态 | **静态类** | `DateTimeUtils.format(...)`、`MoneyUtils.yuanToStr(...)` |
| 有状态 | **实例单例**(保留) | `eventBus`、`sp`、`logCollector` |

- 去除无状态工具的 `final xUtils = XUtils()` 单例与 `factory` 写法，方法改 `static`。调用点 `numUtils.isNum(x)` → `NumUtils.isNum(x)`。
- 保留 `lib/<domain>/*.dart` 平铺结构（**不**强行塞 `lib/src/`），顶层 `cutils.dart` 做 barrel。
- 命名避坑: 不与 Flutter SDK / Dart 内置同名（`DateUtils`、`File`、`Logger` 等需加前缀或改用静态类）。

---

## 5. 依赖变更（`pubspec.yaml`）

**保留**: `shared_preferences`、`path_provider`、`path`、`file`、`archive`、`dartx`、`connectivity_plus`、`device_info_plus`、`package_info_plus`、`uuid`、`event_bus`、`logger`、`crypto`、`convert`、`decimal`

**删除（死依赖）**: `flutter_libserialport`、`rxdart`、`network_info_plus`、`permission_handler`、`plugin_platform_interface`

**dev**: `flutter_test`、`flutter_lints`、`test`、`mocktail`、`path_provider_platform_interface`

> `network_info_plus`、`permission_handler` 经核实零 import；`flutter_libserialport`/`rxdart` 仅被注释/不存在的硬件代码引用；`plugin_platform_interface` 随脚手架删除。
> ⚠️（评审订正）`dartx` 保留正确，但其唯一真实消费者是 `file/file_utils.dart`（`isNullOrEmpty`/`.filter`），非 pubspec 注释所写 "windows 电子秤需要"——需更新注释；`rxdart` 经核实连 `scan_monitor.dart` 也不引用（该文件仅 import `keyboard_util`），属彻底死依赖。

---

## 6. 实现层修复（全量: 高 + 中 + 低）

> 来源: 5 个并行审查 agent 通读全部实现。每条 = `文件:行 — 问题 — 修复方向`。**文件:行 均为当前（重组前）路径**；重组后文件会按 §3 改名/迁移，届时对应同步。所有 high/med 在对应模块单测中以回归用例固化。
>
> ⚓ **锚定规则（评审修订）**: 行号在阶段 2 重组后失效，实现时以**函数/方法名**为稳定锚（如 `_rotateLogFile`、`cleanExpiredLog`、`divideDecString`），行号仅辅助定位。订正: `[0|1|2]` 字符类实际位于 `regex_constants.dart:25/29/33`（原标 24）。

### 6.1 🔴 高危（崩溃 / 栈溢出 / 静默错结果 / 随机删文件 / 安全）

**资源泄漏 & 生命周期**
- `log_collector/log_interceptor.dart:95` — `FlutterError.onError` 内调 `FlutterError.presentError` → 无限递归，首次错误栈溢出。改: 捕获并直接调用先前 handler，不走 `presentError`。
- `log_collector/log_storage.dart:125` — 日志轮转空操作（新文件用同名日期文件名，append 继续写超大文件）。改: 先重命名当前文件（加时间戳后缀）再重指向。
- `log_collector/log_storage.dart:321` — `Timer.periodic` 未保存未取消，`dispose()` 不取消 → 永久触发并持有 `this`。改: 存 Timer，`dispose` 中 `cancel`。
- `log_collector/log_collector.dart:203` — `dispose()` 清 `_outputs` 前不调 `output.dispose()`（`BatchLogOutput` flush 永不执行）。改: 循环 `await output.dispose()` 再清。
- `log_collector/log_collector.dart:45` — `_logQueue` 无上限，高速日志 + 慢 IO 下内存无限增长。改: 加 `maxQueueSize` 上限，满则丢弃/采样。
- `log_collector/log_collector.dart:62` — `initialize()` 双重初始化竞态（await 期间 `_isInitialized` 仍 false）。改: 同步置 `_isInitializing` 或用 `Completer`。
- `log_collector/log_output.dart:32,39` — `ConsoleLogOutput` 用 `print()`（违 CLAUDE.md，且会被 debugPrint 拦截器捕获形成噪音）。改: 用 `debugPrint`/`developer.log`。
- `text/calculate_utils.dart:11,23,32,44` — `TextPainter` 从不 `dispose()`，每次调用泄漏原生文本整形资源。改: `try/finally` 中 `painter.dispose()`。

**静默错结果 / 崩溃**
- `file/file_utils.dart:370` — `readBySink` 立即 `return ""`，`listen` fire-and-forget，永远读不到内容。改: `await for` 或 `Completer<String>`。
- `file/file_utils.dart:469` — `cleanExpiredLog` 用 `lastModified.millisecond`（0–999 分量）比 epoch 毫秒 → 数学无意义、随机删文件。改: `millisecondsSinceEpoch`。
- `file/file_utils.dart:419`/`:553`/`:473` — `file.delete()`、`encoder.close()`、`Directory.list().forEach()` 返回的 Future 未 await（函数提前返回 / zip 可能不完整 / 删除不发生）。改: 全部 await。
- `file/file_utils.dart:598` — `deleteLog` 忽略 `saveDays` 参数，硬编码 `>3`。改: 用 `differDays > saveDays`。
- `file/file_utils.dart:132` — 路径穿越：`filePath`/`fileName` 直接用 `/` 拼接，`../../` 可逃逸且 Windows 不兼容。改: 用 `p.join` 并拒绝含 `..`/绝对路径的段。
- `regex/regex_constants.dart:99,110,114,123,127,131,136` — 整数/浮点正则 `^...|...$` 未加括号，`^`/`$` 只绑首尾分支 → `REGEX_INTEGER` 匹配 `"123abc"`。改: `^(?:...|0)$`。
- `regex/regex_constants.dart:24` — `[0|1|2]` 是字符类，`|` 被当字面量匹配。改: `[012]`。
- `regex/regex_utils.dart:83` — 身份证尾号小写 `x` 被判无效。改: `input[17].toUpperCase()`。
- `date/date_utils.dart:115` — `SSS` 毫秒格式 ms<100 只出 2 位。改: `padLeft(3,'0')`。
- `date/date_utils.dart:208` — `isToday` 传 `locMs` 时忽略 `isUtc`，跨时区跨日判定错。改: `getDateTimeByMs(locMs, isUtc: isUtc)`。
- `time/timer_util.dart:56` — 倒计时用"每次 tick 递减"，`Timer.periodic` 漂移，长倒计时与墙钟脱节。改: 一次性记 `endTime`，每 tick 算 `endTime.difference(now)`。
- `time/timer_util.dart:71,102` — `Future.delayed` 不被 `cancel()` 取消，重启串台。改: 存入字段，`cancel()` 中取消。
- `num/num_utils.dart:64` — `*Num()` 号称不丢精度却返回 double，大数走科学计数法时 `Decimal.tryParse` 失败 → 静默返回 `0.0`。改: 返回 `Decimal` 或显式声明 double 限制并禁用静默 0.0。
- `num/num_utils.dart:172` — `(a/b).toDecimal()` 在 `1/3` 非终止小数下抛 `StateError`。改: `scaleOnInfinitePrecision: 20`。
- `num/money_utils.dart:47` — `int.parse(amountStr)` 空/非法/溢出直接抛。改: `int.tryParse` + 明确异常或默认值。
- `ext/double_ext.dart:35` — 千分位负数 → `-,100.00`（负号当数位）。改: 先剥离符号格式化绝对值再补回，或 `intl NumberFormat`。
- `system/device_info_util.dart:110` — `winUniqueIdentifier` 混入 `DateTime.now()` → 每次调用都变，失去唯一性。改: 仅拼接稳定硬件 ID。
- `system/keyboard_util.dart:29` — `closeKeyBoard` 副作用把状态栏/导航栏一起藏（`SystemUiMode.immersive`）。改: 移除副作用，系统 UI 切换独立成方法。
- `system/system_utils.dart:99` — `navigationBarHeight` 用 `(padding.bottom - padding.top)/dpr`，算式错（常为负）。改: `padding.bottom / dpr`。
- `net/net_util.dart:35` — Windows 直接 `return true` 当永远在线。改: 走相同连通性检测。
- `net/net_util.dart:50` — 只取 `result[0]`，丢弃 wifi+vpn 等多结果。改: 遍历，"任一非 none"即在线。
- `net/net_util.dart:67` — 蓝牙当断网。改: 视为在线或文档说明。
- `encrypt/encrypt_utils.dart:25` — `encodeMd5File` 用 `readAsStringSync` 读二进制 → hash 被破坏，且阻塞 + 全量入内存。改: `md5.bind(file.openRead()).last`。

**安全 / 正确性风险**
- `regex/regex_constants.dart:36` / `regex_utils.dart:92` — 邮箱正则嵌套量词 `([-+.]\w+)*` 存在 **ReDoS**。改: 换 `^[^\s@]+@[^\s@]+\.[^\s@]+$` 等非回溯模式 + 长度上限。
- `encrypt/encrypt_utils.dart:33` — `xorCode` 无输入校验，非整数字段抛 `FormatException`；代理对范围产生 ill-formed UTF-16，后续 `utf8.encode` 破坏往返。改: 校验输入、全程用 `List<int>`、base64 原始字节。
- `sp/sp_util.dart:140` — getter 把 `value` 打进 info 日志 → token/PII 泄露。改: 仅记 key，或 debug 开关控制。
- `utils/random_utils.dart:12` / `utils/uuid_utils.dart:16` — 用非安全 RNG，不适合 token/ID。改: 提供 `Random.secure()` / `Uuid(cryptoRNG)` 选项，ID 类默认安全。
- `file/file_utils.dart:637` — `createFileFromBase64` 无 try/catch，非法 base64 抛裸 `FormatException`。改: 包装抛类型化异常。

### 6.2 🟡 中危（选要）
- `json/json_utils.dart:78` `encodeObjectList` 空列表返回 `null`（应 `"[]"`）；`:97` `json.decode` 大整数精度丢失（用 reviver 或文档）。
- `json/json_utils.dart:21` `printJson` 命名踩 CLAUDE.md 禁词 → 改 `logJson`/`prettyEncode`。
- `sp/sp_util.dart:23` `init` 竞态（并发都过 null 检查）→ 存在途 Future 单次化；`:81` `putObject` 名不副实（需传 Map）→ 改名/收 `toJson`；`:96` 旧 idiom → `.whereType<String>()`。
- `net/net_util.dart:53` switch 非穷尽，vpn/tethering/mixed 落 default 当 none → 逐 case；`:40` 缓存不刷新不订阅 stream → 订阅 `onConnectivityChanged` 并 dispose；`:49` 无 timeout。
- `regex/regex_utils.dart:98,116` `isURL`/`isIP` 未锚定 → 加 `^...$`；`:154` `isNumeric` 接受 `"123."` → 要点后必有数字；`:238` `isJSON` 语义不清 → 文档化。
- `regex/regex_constants.dart:140,148,156+` 小写 `email`/`url`/文件扩展正则与 `REGEX_*` 重复且冲突、`.` 未转义、大小写敏感 → 选一套删另一套，`^.+\.(?:...)$`+`(?i)`。
- `num/num_utils.dart:88` 经 `toString()` 中转，`num` 入参已在损坏值上运算 → 提供 `Decimal`/`String` 重载并文档。
- `num/money_utils.dart:23` Decimal→double→toStringAsFixed 大额丢精度 → 直接由 Decimal 格式化；`:61` enum switch 有 default 失去穷尽 → 去 default。
- `ext/string_ext.dart:53` `formatMoney` 大数科学计数法；`:60` 与 double_ext 重复且未声明单位(分) → 文档化/去重。
- `ext/int_ext.dart:84` `percentFormat` 文档示例用 `0.25` 但扩展在 `int` → 修文档；`:87` `this!*100` 溢出风险 + `¥` 前加空格 → 文档/去空格。
- `ext/double_ext.dart:68` `percentFormat` 不乘 100 而 int 版乘 100，同名不同义 → 统一。
- `ext/object_ext.dart:8` `isNullOrBlank` 把 `0` 当空 → 去 `0` 规则或改名文档化；`:13` `this is! bool` 死代码（bool 非 num 子类型）。
- `date/date_utils.dart:62` `getYesterday` 减 24h，DST 边界错 → 减一个日历日；`:204` `ms==0` 当"非今天"误伤 epoch 0；`:217/248/598` 跨时区比较未归一；`:289` `nextMonth` 返回 int 而同类返回 DateTime → 统一。
- `date/data_formats.dart:8` `static final` 字面量应 `const`；`:35` `MONTH_DAY` 全局可变 map → `const` 私有。
- `time/timeline_util.dart:19` `ArgumentError.checkNotNull` 已废弃 + 死代码；`:91` 用后缀字符串判方向 → 用 enum；`:75` isUtc 未贯穿；`:127` 未来日期走"今天"格式语义错。
- `time/timer_util.dart:88` `updateTotalTime` 副作用重启 → 拆 `setTotalTime`+显式 start；缺 `dispose()` → 补并文档化生命周期。
- `log_collector/log_storage.dart:91` `_memoryStorage.removeAt(0)` O(n) → 用 Queue；`:104` 每条两次 IO 查大小 → 内存记 `_currentFileSize`；`:113` 每条 `flush:true` → 定时批量 flush；`:213` 查询全文件读入内存 → 流式短路。
- `log_collector/log_collector.dart:128` store 无 try/catch，存储抛错致队列不排空 → 包装；`:131` 迭代 `_outputs` 与增删并发修改 → 迭代快照；`:157` `interceptor.start` 未 await。
- `log_collector/log_output.dart:119` `BatchLogOutput` 无 Timer，无流量时缓冲无限等待 → 定时 flush；`:133` flush 先清缓冲，delegate 抛错丢剩余且不隔离 → 逐条 try/catch；`:60` FileLogOutput/NetworkLogOutput 是 TODO 桩却收参 → 实现或标 abstract。
- `log_collector/log_interceptor.dart:131` onStop 不还原原 handler → 保存并恢复；`:138` `FileLogInterceptor` 全 TODO 死代码 → 实现/删除。
- `utils/event_bus_util.dart` 无 dispose/destroy，遗忘取消的订阅永久泄漏 → 注册集 + dispose 关 controller。
- `text/text_utils.dart:154` `reverse` 按 codeUnit 破坏 emoji → 用 runes；`:57` `abbreviate("x",2)` 越界 → 守卫 `maxWidth<4`；`:131` `formatDoubleComma3` 无小数时越界 → 校验 `length==2`。

### 6.3 🟢 低危（选要，重组时顺手）
- 通用: 去掉违规 `!`（改局部变量绑定）、字面量加 `const`、可变全局集合改 `const`/私有不可变、`== true` 死判断、`var`→`final`、单引号、行宽 ≤80、`dart format`。
- 重复 API 去重: `numUtils` 全局 vs `factory` 二选一、`safeValue`/`defaultValue` 合并、`moneyFormatWithUnit` 两文件重复、两套 `percentFormat`、`regex_constants` 的 `REGEX_*` 与小写常量两套。
- 死代码: `net/url_utils.dart` 空类（删或实现）、`ext/bool_ext.then` 误导命名、`abs_time_info.weeks` 未用、`log/log.dart` 六方法重复。
- 文档与实现不符: `day_format.dart` 阈值描述、`keyboard_util.dart` isCapsLock、`int_ext.percentFormat` 示例、`time/*_info` 重复类共享基类。
- 命名: `deviceInfo` 全局/getter/局部三重遮蔽、`money_unit` 枚举 `SCREAMING_SNAKE`→camelCase、`foucusNode` 拼写、`"unKnow"`→`"unknown"`。
- `log_entry.dart` `extra` 深不可变(copy)；`StackTrace.fromString` 先 `as String?`。

---

## 7. 测试策略

- **现状**: 仅 `file/file_utils_test.dart` 是真测试；`cutils_test.dart`/`cutils_method_channel_test.dart` 仅测 plugin 脚手架（随脚手架删除）。
- **目标**: 每个公开工具都有单测（`package:test` + `mocktail`，Arrange-Act-Assert）。
  - 纯逻辑优先且全量: `num`/`ext`/`datetime`/`regex`/`json`/`crypto`/`string`/`identifier`/`text`。审查报告的每个边界缺失都转为一条回归用例（负数、空、溢出、DST、跨时区、ReDoS 输入、非法 JSON/base64、大整数等）。
  - 有状态配 mock: `file`/`storage`/`log_collector`/`system`/`net`（沿用 `MockPathProviderPlatform` 等）。
  - **计时类用 fake time**: 涉 Timer 的回归（`timer_util` 漂移、`log_storage` 每日清理、`BatchLogOutput` 间隔 flush）用 `FakeAsync`/`clock` 驱动，避免慢测或 flaky。
- 删除: `test/cutils_test.dart`、`test/cutils_method_channel_test.dart`。
- 每阶段结束 `flutter test` + `dart analyze` 必须双绿。

---

## 8. 文档与示例

- **dartdoc**: 每个公开 API 加 `///`，含一行可运行示例（呼应 CLAUDE.md）。修正所有"文档与实现不符"项（§6.3）。
- **`example/`**: 现 `main.dart` 只 demo `getPlatformVersion`（删）。扩为**按领域分组的演示页**（num/datetime/regex/json/crypto/storage/ext … 各一屏可交互 demo）。
- **README**: 替换占位 README，写明定位、安装、各模块一句话索引 + 链接到 example。
- 更新 `CLAUDE.md` 反映新结构（模块地图、barrel、约定）；**纠正 stale 描述**: `scan_monitor.dart` 实测仅 import `keyboard_util`，不引入 `rxdart`/`dartx`（原文称 scanner 引入二者，已过时）。
- **CHANGELOG & 版本**: 更新 `CHANGELOG.md`——按模块列破坏性变更，重点: import 路径迁移、单例→静态、常量语义变更（见 §11 D5）、Decimal 契约（见 §11 D2）；`pubspec.yaml` 版本 `0.0.1 → 0.1.0`（pre-1.0 破坏性）。

---

## 9. 迁移

`cutils` 被 `cashier` 以 path/git 依赖按完整路径 import。重构后两处会断:
1. import 路径（合并/改名/解散）。
2. 单例→静态类调用点（`numUtils.x`→`NumUtils.x`）。

策略: 先改 `cutils`（含测试、analyze 干净），再同步过一遍 `cashier` 的 import 与调用点；引导 `cashier` 改用 `import 'package:cutils/cutils.dart';` barrel 以降未来 churn。

**前置检查（阶段 1 前）**: grep cashier 对 `Cutils`/`getPlatformVersion` 的引用——删脚手架（S9）前确认无调用（参照 `example/lib/main.dart:35` 的用法）；若有，先在 cashier 移除。

---

## 10. 分阶段落地

1. **清理**: 删死代码/死依赖/plugin 脚手架/`scanner`/`example` 内 usage_example；删两个脚手架测试；更新 pubspec `dartx` 注释与 CLAUDE.md 模块地图（见 §8）。
2. **重组**: S1–S10 结构改动 + barrel；`analyze` 干净。
3. **高危修复 + 回归测试**: §6.1 逐条修，每条配测试。
4. **中危修复 + 测试**: §6.2。
5. **低危清理 + 文档/dartdoc**: §6.3 + §8 dartdoc。
6. **`example/` 演示页 + README**。
7. **迁移 cashier**。

每阶段: `dart format` → `dart fix --apply` → `dart analyze` 零告警 → `flutter test` 全绿。

---

## 11. 待决议项（评审后强化）

> 评审结论: §6 bug 清单已逐条核实属实，准确度高。下列各项是"会被多个 Flutter 项目引用"这一约束下**必须在实现前拍板**的契约/策略决定，不再作为"待定"延后。每项给出背景、选项与推荐。

### D1. 公开 API 边界与版本策略【最高优先】
- **背景**: §1 称"可发布 pub.dev、保持签名稳定"，§4 称"保留 `lib/<domain>/*.dart` 平铺、不强行 `lib/src/`"，§9 称"引导 cashier 用 barrel"。只要平铺文件可被外部 import，它就*事实上*是公开 API；同时鼓励 barrel 等于背书两套 import，公开表面积翻倍，内部任何移动文件都是 break。
- **选项**:（A）barrel 为**唯一**公开入口，实现挪到 `lib/src/`，full-path import 不保证稳定；（B）显式声明"barrel + 各 domain 文件**都**公开"，接受翻倍维护成本；（C）**混合制**——公开 API = 显式 blessed 路径清单（叶子领域文件本身 + 子系统门面 + 顶层便利 barrel），`lib/src/` 仅放跨模块共享 helper，1.0 冻结清单内路径。
- **推荐**: **C**（评审深化后修正原"A"）。util 库的卖点恰是"按领域按需 import"，纯 barrel 会让扩展变 all-or-nothing、加剧 D4 污染；且 cashier 等 full-path 现状迁移成本最低。封装诉求只对子系统成立（`log_collector` 已有 `log_collector_export.dart` 门面），叶子 util 无需藏进 src/。落地动作: 在 README/CLAUDE.md 维护一份 blessed 公开路径清单，清单外（`lib/src/`、子系统内部文件）不保证稳定——清单即契约。
- **版本**: 本次破坏性重构 `0.0.1 → 0.1.0`（pre-1.0，允许 break）；`1.0.0` = 公开 API 冻结里程碑。CHANGELOG.md 已存在，须随本次更新（见 §8）。

### D2. Decimal 精度契约【最高优先】
- **背景**: 原文"需在实现时定每方法返回型"——不可延后。代码已暴露**自相矛盾的双面 API**: `addDec()` 返回 `Decimal?`、`addNum()` 返回 `double` 却文档标注 "without loosing precision"。§6.1 的"大数静默 0.0"正是此矛盾的产物。
- **决议项**:（1）四则规范返回型 = `Decimal`（`*Dec()` 已是，既成事实）。（2）`*Num()` 这批返回 double 的方法: **删除**或改名 `*Double()` 并显式标注"有损"，消除"文档写 without loosing precision、实则 `toDouble()`"的谎言。（3）**输入侧精度漏洞写进契约**: 精确路径优先收 `Decimal`/`String`；收 `num` 的重载须文档化"按 `toString()` 解析，仅对字面量/小值安全"（调用方传已算过的 double 如 `0.1+0.2`，精度在进 cutils 前已丢）。（4）除法非终止小数（1/3）默认 scale: `scaleOnInfinitePrecision`（建议 20，可配）。（5）**解析失败不静默**: 禁止 `?? 0.0` 兜底，改为抛或返回 `null`。
- **推荐**: 规范型 = `Decimal`；`*Dec()` 保留为精确入口，`*Num()` 删除或诚实标注有损；接受与 `package:decimal` 的耦合（此模块的全部意义即精度，decimal 成熟稳定）。

### D3. 全局单例的生命周期归属
- **背景**: `eventBus`/`sp`/`logCollector` 是进程级单例，多消费者共享。§6.2 把"eventBus 无 dispose / sp init 竞态"当 bug，但更上层契约缺失: 消费者 A 调 `logCollector.dispose()` 会杀掉消费者 B 的日志。
- **决议**: 声明这些为 **App 级单例**，由**宿主 App** 启动时 init 一次、退出时 dispose；`dispose()` 文档化为"仅供宿主 App 调用"，库消费者不得各自 dispose。§6.2 的 init 竞态（sp、logCollector）按此契约修复（Completer / 在途 Future 单次化）。

### D4. 扩展方法的全局污染
- **背景**: §4 把扩展列为首选 API 形式，barrel 会 re-export 全部 `ext/`，随 barrel 全局注入，可能与消费者自身扩展或其他库撞名。
- **决议**: 扩展名审计（避 `String.format`/`num.toX` 等高频通用名）；文档化"扩展随 barrel 注入"并列出注入清单；易撞名扩展考虑单独导出、不进 barrel。

### D5. 常量改语义 = 破坏性变更（需进 CHANGELOG）
- **背景**: `REGEX_INTEGER`/`REGEX_EMAIL` 等是公开常量。修 `^...|0$` 锚定与 ReDoS 是对的，但 `RegExp(REGEX_INTEGER).hasMatch(x)` 返回值会变；ReDoS 修复后 `REGEX_EMAIL` 会**更宽松**（接受更多串），依赖其拒收的消费者有 surprise。
- **决议**: 按"行为变更"而非纯 bugfix 处理 → CHANGELOG 列 before/after；优先"保留旧常量名 + 修正实现"（同语义升级）；§6.2"两套重复"删一套照旧。

### D6. log_collector 桩 & 硬件子包（沿用原结论）
- `FileLogOutput`/`NetworkLogOutput` TODO 桩: 本次**先标 abstract + 文档**，避免半成品（沿用原文倾向）。
- 硬件子包 `cutils_pos` 为后续独立 spec。

### D7. 分阶段顺序（微调）
- §6 用 `文件:行` 锚定，阶段 2 重组后行号集体失效。缓解二选一:（a）给每条 §6 记录补**稳定锚 = 函数/方法名**，行号仅辅助；（b）高危修复（阶段 3）与重组（阶段 2）就近合并，先修后搬。
- **推荐**: **a**（成本最低），已在 §6 引言落地。

---

## 12. 评审修订记录（2026-08-07）

- **评审方法**: 逐行核实 §6 高危清单（约 15 条，跨 `file_utils` / `regex_constants` / `log_collector` 全家桶 / `num_utils`）与依赖/耦合分析，全部属实；行号基本准确（约 8 处 1–8 行小漂移，无"差几十行/指错文件"的大错；已按 D7 以**函数名为主锚、行号为辅**）。
- **本修订内联修正**:
  - §6 引言: 增加"函数名优先、行号为辅"锚定规则；订正 `[0|1|2]` 实际行号（25/29/33，非 24）。
  - §5: 订正 `dartx` 真实消费者为 `file/file_utils.dart`；确认 `rxdart` 彻底死依赖。
  - S5/S6/S7: 补 `text_utils` 非谓词方法去向、`EncryptUtils` 类名一致性、`sp` 单例新名。
  - §7: 计时类回归测试用 `FakeAsync`/`clock` 驱动。
  - §8: 交付物补 CHANGELOG.md 更新 + 版本 `0.0.1 → 0.1.0`。
  - §9: 迁移前置检查 cashier 是否调用 `Cutils.getPlatformVersion()`。
  - §10: 阶段 1 增"更新 pubspec `dartx` 注释与 CLAUDE.md 模块地图"。
- **评审待办（见 §11 D1–D7）**: **D1 公开 API 边界**、**D2 Decimal 契约**为最高优先，须作者拍板后方可进入阶段 3 及之后。
