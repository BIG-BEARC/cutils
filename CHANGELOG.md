# CHANGELOG

本文件记录 `cutils` 的发布变更。

## 0.1.0 — 重构与质量提升（破坏性）

由 plugin 包重组为纯 Dart/Flutter 工具库，全面整理目录结构与公开 API，并修复一批高危 bug。
**pre-1.0 版本，API 可能随版本演进。**

### 重构 / 结构

- 由 plugin 包降级为普通 Dart/Flutter 包（移除 `method_channel` / `platform_interface` /
  `android` / `ios` / plugin 脚手架与脚手架测试，中和 `example`）。
- 新增顶层 barrel `lib/cutils.dart`，一行导入即可使用全部核心工具：
  `import 'package:cutils/cutils.dart';`。
- 目录重组：
  - `date/` + `time/` → `datetime/`
  - `encrypt/` → `crypto/`
  - `sp/` → `storage/`
  - 解散 `utils/` grab-bag → `event/` + `ui/` + `identifier/`
  - `text/` 拆入 `ui/` + `ext/`
- 移除硬件相关死代码：`scanner/`、`system/serial_util`（延期到独立子包 `cutils_pos`）。
- 清理死依赖与 pubspec plugin 段。

### API 风格（无状态工具转静态类）

下列无状态工具由「实例 + 单例」改为「静态类」，调用点 `xUtils.foo()` → `XUtils.foo()`：

- `NumUtils`、`DateTimeUtils`、`CryptoUtils`、`JsonUtils`、`RandomUtils`、`UUIDUtils`、
  `KeyBoardUtils`、`RegexUtils`、`MoneyUtils`。

保留实例单例（有状态）：`spUtil`、`logCollector`、`eventBus`、`netUtil`、`deviceInfo`、
`packageInfoUtil`、`logger`。

### 重命名

- `DateUtils` → `DateTimeUtils`（避开 Flutter SDK 的 `DateUtils` 同名）。
- `EncryptUtils` → `CryptoUtils`。
- `printJson` → `logJson`（保留 `@Deprecated` 别名）。
- `putObject` → `putJsonable`（保留 `@Deprecated` 别名）。
- `TimerUtil.updateTotalTime` → 纯 setter（不再隐式重启），新增 `restart()` 承接旧行为。

### 语义 / 行为变更

- **正则**：`REGEX_INTEGER` / `REGEX_FLOAT` 等全锚定（`"123abc"` 不再误判）；
  `REGEX_EMAIL` 改非回溯模式 + 254 上限（更宽松、抗 ReDoS）；`isURL` / `isIP` 全锚定；
  `isNumeric("123.")` → `false`；`isJSON` 收紧为仅对象 / 数组。
- **数值**：`NumUtils.*Num()` 遇非有限输入抛 `ArgumentError`（原静默返回 `0.0`）；
  `divideDec(1, 3)` 不再抛异常。
- **金额**：`MoneyUtils.changeF2Y*` 遇非法 / 溢出抛 `ArgumentError`（原裸 `FormatException`）；
  大额精度改 Decimal 直格式化。
- **加解密**：`CryptoUtils.xorBase64*` 编码改为原始 UTF-8 字节 base64
  （原 code-unit 路径对代理对输入会抛）；`CryptoUtils.encodeMd5File` 改流式字节
  （原读字符串破坏二进制 hash）。
- **文件**：`createFileFromBase64` 抛类型化 `InvalidBase64Exception`。
- **系统**：`KeyBoardUtils.closeKeyBoard` 不再隐藏系统 UI（移除 immersive 副作用）；
  `NetUtil`：Windows 不再硬编码在线、蓝牙计为在线、多结果聚合（任一非 `none` = 在线）。
- **扩展**：`double_ext.percentFormat` 改为 ×100；`object_ext.isNullOrBlank` 不再把 `0`
  当空；`int_ext.currencyFormatWithSymbol` 去符号后空格；`string_ext.formatMoney` 整元不再
  追加 `.0`。
- **日期时间**：`DateTimeUtils.nextMonth` 返回 `DateTime`（原 `int`）；`getYesterday` 改日历日
  （DST 正确）；`isToday` / `isWeek` 不再把 `ms == 0` 当「无值」。
- **JSON**：`JsonUtils.encodeObjectList([])` 返回 `"[]"`（原 `null`）。

### 删除（未用，0 调用方）

- 14 个 lowercase 正则常量（email / url / hexadecimal / vector / image / audio / video /
  txt / doc / excel / ppt / apk / pdf / html）。
- `net/url_utils.dart`（空 `UrlUtils`）。
- `ext/bool_ext.then`。
- `TimelineInfo.weeks`。

### 修复的高危 bug（简列）

- **log_collector**：FlutterError 递归 / 轮转空操作 / Timer 泄漏 / dispose 不释放 outputs /
  队列无上限 / init 竞态 / ConsoleLogOutput 用 `print`。
- **file_utils**：`readBySink` 空返回 / `cleanExpiredLog` 用 `.millisecond` 致随机删 / 多处
  未 await / `deleteLog` 忽略 `saveDays` / 路径穿越。
- **datetime**：SSS 毫秒格式 / `isToday` isUtc / 倒计时漂移 / `Future.delayed` 不取消。
- **system**：`winUniqueIdentifier` 混入 `DateTime.now` / `navigationBarHeight` 算式。
- **ext**：千分位负数 / `TextPainter` 不 dispose / sp 把 value 打进日志（PII）。

## 0.0.1

初始占位版本（plugin 脚手架）。
