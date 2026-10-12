# CHANGELOG

本文件记录 `cutils` 的发布变更。

## 0.3.0 — 吸收 YCFlutterUtils 三件能力（byte / 元转分 / 校验族）

自 YCFlutterUtils 按「能力吸收、重写」落地三件（非文件拷贝：源实现为
pre-null-safety 代码且带缺陷，本批全部按本仓基线重写并修正）：

- **新增 `lib/byte/` 字节工具模块**（零第三方依赖，仅 `dart:typed_data` /
  `dart:convert`）：`ByteUtils`——可读字符串 ↔ `Uint8List`（hex/dec，值域
  校验拒绝超 `0xFF` token，不做静默截断）、base64 互转、克隆 / 判等与
  截取 / 拼接 / 插入 / 删除窗口操作（越界钳制，不修改入参）；`ByteWord` /
  `ByteDoubleWord`——16 / 32 位整数按显式 `Endian` 序列化拆装。
- **`MoneyUtils.changeY2F(String) → int` 元转分**：与 `changeF2Y` 对称，
  Decimal 全程不经 `double`（2^53 边界外不丢精度）；无法解析、非整分、
  换算分值超出平台 int 范围均抛 `ArgumentError`。
- **`RegexUtils` 新增 15 个校验方法与配套 `REGEX_*` 常量**：文件类型族 11
  （isImage / isAudio / isVideo / isTxt / isDoc / isExcel / isPpt / isApk /
  isPdf / isHtml / isVector——扩展名启发式，双端锚定 + 转义分隔点，大小写
  不敏感）、哈希格式族 3（isMD5 / isSHA1 / isSHA256——仅格式校验，非校验
  和；支持冒号分隔形态）、`isHexadecimal`（裸十六进制串，与 `isHexColor`
  颜色格式语义不同）。

## 0.2.1 — log_collector 条目级压制控制台输出

`LogEntry` 新增 `suppressConsole` 标志（默认 `false`，既有行为不变）：置 `true`
的条目照常进入采集管线（内存 + 文件，`getLogs` / `export` 可查），仅分发时跳过
控制台类输出器——适合 release 下低值 / 高频日志留档不刷屏。

- `LogCollectorHelper` 六个级别方法（`log` / `debug` / `info` / `warning` /
  `error` / `fatal`）新增同名可选参数透传。
- `LogOutput` 基类新增 `isConsole` 契约 getter（默认 `false`）：向控制台写入的
  自定义输出器须 override 为 `true`；包装 / 委托型输出器须转发
  `delegate.isConsole`（`ConsoleLogOutput` / `BatchLogOutput` 已内置正确实现）。
- 语义边界：不追溯拦截来源已上控制台的原始输出（如 `debugPrint` 原始打印）；
  标志仅进程内路由有效，不进 `toJson` 持久化。
- 方案经独立评审闭环，记录见 `docs/评审-plan-log-suppress-console.md`；新增
  15 个测试用例（`test/log_collector/log_collector_suppress_console_test.dart`）。

## 0.2.0 — 命名统一（破坏性）

全部工具类后缀统一为 `*Utils`（21/21），消除 Util/Utils 双轨与两处拼写不规范。
**文件名与 import 路径不变**；顶层小写实例（`spUtil` / `netUtil` / `eventBus` /
`deviceInfo` / `packageInfoUtil` / `logger`）不变；**不保留旧名别名**（pre-1.0
且无存量下游，留别名只会延长双轨）——按旧名调用的下游按下表改名调用点即可。

| 旧类名 | 新类名 |
|---|---|
| `UUIDUtils` | `UuidUtils` |
| `KeyBoardUtils` | `KeyboardUtils` |
| `NetUtil` | `NetUtils` |
| `TimerUtil` | `TimerUtils` |
| `SpUtil` | `SpUtils` |
| `TimelineUtil` | `TimelineUtils` |
| `DeviceInfoUtil` | `DeviceInfoUtils` |
| `EventBusUtil` | `EventBusUtils` |
| `PackageInfoUtil` | `PackageInfoUtils` |

### 文档

- 各工具模块头补依赖标注（平台插件面显式标出，提醒下游集成 / 打桩成本）与
  `log/` ↔ `log_collector/` 双轨定位说明；`log_collector` 经 `log_storage` 依赖
  `path_provider` 一并显式化。

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
- 清理死依赖与 pubspec plugin 段；移除 `dartx`（仅剩一处 `.filter` 用法，
  已改为 `dart:core` 的 `where`；`StringExt.isNullOrEmpty` 与其同名扩展的
  语义冲突随之消除）。

### API 风格（无状态工具转静态类）

下列无状态工具由「实例 + 单例」改为「静态类」，调用点 `xUtils.foo()` → `XUtils.foo()`：

- `NumUtils`、`DateTimeUtils`、`CryptoUtils`、`JsonUtils`、`RandomUtils`、`UUIDUtils`、
  `KeyBoardUtils`、`RegexUtils`、`MoneyUtils`。

保留实例单例（有状态）：`spUtil`、`logCollector`、`eventBus`、`netUtil`、`deviceInfo`、
`packageInfoUtil`、`logger`。

### 重命名

- `NumUtils` 的 `*Dec` / `*DecString` 精确计算族（`addDec` / `subtractDec` /
  `multiplyDec` / `divideDec` / `remainder` 及对应 `*DecString`）返回类型由
  `Decimal?` 改为 `String?`（十进制字符串）——`Decimal` 收回为内部实现，
  不再暴露在公开签名（下游无需直接依赖 `decimal` 包）。失败语义不变
  （解析失败 / 除零仍返回 `null`）。
- `SpUtil.init()` 返回类型由 `Future<SharedPreferences?>` 改为 `Future<bool>`
  （成功返回 `true`，失败抛出）——`SharedPreferences` 对象不再外泄到公开签名，
  需要原始实例时仍可用 `getSp()`。
- `moneyFormatWithUnit`（`StringExt` / `DoubleFormating` 两处）改走 `Decimal`
  运算（与 `formatMoney` 同策略），大额输入（2^53 边界附近）不再丢精度；
  `Decimal` 无法解析的异形输入回退旧 double 路径，行为兼容。
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
  未 await / `deleteLog` 忽略 `saveDays` / 路径穿越 / `getFileList`·`deleteLog` 枚举日志改
  后缀匹配 + 排除目录链接（原子串匹配会误收 `*.log.bak` 与名为 `*.log` 的目录，zip 压缩
  目录即抛）/ `cleanLog` 排除目录链接（原空 `*.log` 目录会被静默删除）/ 过期判定
  `ctime` 改 `mtime`。
- **datetime**：SSS 毫秒格式 / `isToday` isUtc / 倒计时漂移 / `Future.delayed` 不取消。
- **system**：`winUniqueIdentifier` 混入 `DateTime.now` / `navigationBarHeight` 算式。
- **ext**：千分位负数 / `TextPainter` 不 dispose / sp 把 value 打进日志（PII）。

## 0.0.1

初始占位版本（plugin 脚手架）。
