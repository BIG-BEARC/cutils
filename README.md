# cutils

> 通用 Flutter 工具库（纯 Dart + Flutter 框架 + 通用平台插件）。

一组互相独立的 Dart/Flutter 工具模块，作为依赖被其他 App 引用——**不是**可独立运行的
App。没有 `lib/main.dart`；`example/` 是演示用 demo。

## 安装

### pub.dev

```yaml
dependencies:
  cutils: ^0.1.0
```

### git / path

```yaml
dependencies:
  cutils:
    git: https://github.com/BIG-BEARC/cutils.git
    # 或本地路径：
    # path: ../cutils
```

## 最小用法

一行 barrel 导入即可使用全部核心工具：

```dart
import 'package:cutils/cutils.dart';

// 日期格式化
final today = DateTimeUtils.formatDate(DateTime.now(), format: 'yyyy-MM-dd');
// → "2026-08-10"

// 金额（分→元，基于 Decimal，不丢精度）
final yuan = MoneyUtils.changeF2Y(1999); // → "19.99"

// 类型扩展
final ok = 'a@b.com'.isEmail; // → true
```

> 按需导入单个模块也支持：
> `import 'package:cutils/num/money_utils.dart';`

## 模块地图

按领域划分，每个模块互相独立，可单独 import：

| 领域 | 目录 | 说明 |
|---|---|---|
| 数值 / 金额 | [`num/`](lib/num) | `money_utils`、`money_unit`、`num_utils`，基于 `decimal` 高精度计算 |
| 类型扩展 | [`ext/`](lib/ext) | `string_ext`、`int_ext`、`double_ext`、`bool_ext`、`object_ext`、`widget_ext`（`ext_fun.dart` 是 barrel） |
| 日期时间 | [`datetime/`](lib/datetime) | `DateTimeUtils`、`timeline_util`、`timer_util` 及 zh/en 本地化信息 |
| 正则 | [`regex/`](lib/regex) | `RegexUtils` + `regex_constants` |
| JSON | [`json/`](lib/json) | `JsonUtils` 编解码 / 美化 |
| 加解密 | [`crypto/`](lib/crypto) | `CryptoUtils`（`crypto` 包；md5 / hmac / base64 / xor） |
| 文件 | [`file/`](lib/file) | `FileUtils` 读写 / base64 / 过期清理 |
| 存储 | [`storage/`](lib/storage) | `SpUtil`（SharedPreferences 封装，顶层实例 `spUtil`） |
| 网络 | [`net/`](lib/net) | `NetUtil`（`connectivity_plus` 在线判断，顶层实例 `netUtil`） |
| 系统 | [`system/`](lib/system) | 设备信息（`deviceInfo`）、包信息（`packageInfoUtil`）、键盘、系统工具 |
| UI | [`ui/`](lib/ui) | `calculate_utils` 文本测量、`image_utils` |
| 事件 | [`event/`](lib/event) | 事件总线（顶层实例 `eventBus`） |
| 标识 | [`identifier/`](lib/identifier) | `random_utils`、`uuid_utils` |
| 日志 | [`log/`](lib/log) | `logger` 包薄封装（顶层实例 `logger`） |
| 日志收集 | [`log_collector/`](lib/log_collector) | 完整日志收集子系统（顶层实例 `logCollector`，详见 [README](lib/log_collector/README.md)） |

## API 风格

cutils 按工具是否有状态选择不同 API 形态：

- **无状态工具 = 静态类**：`NumUtils.foo()`、`DateTimeUtils.foo()`、`CryptoUtils.foo()`、
  `JsonUtils.foo()`、`RegexUtils.foo()`、`MoneyUtils.foo()`、`RandomUtils.foo()`、
  `UUIDUtils.foo()`、`KeyBoardUtils.foo()`。无需创建实例，直接类名调用。
- **类型相关 = 扩展**：挂在内置类型上，如 `'x'.isEmail`、`42.currencyFormat()`、
  `0.5.percentFormat()`。
- **有状态 = 实例单例**：直接用预置的顶层实例，无需自己 `new`：
  - `spUtil` —— SharedPreferences 持久化
  - `logCollector` —— 日志收集子系统
  - `eventBus` —— 事件总线
  - `netUtil` —— 网络在线判断
  - `deviceInfo` / `packageInfoUtil` —— 设备 / 包信息
  - `logger` —— 控制台日志

## 示例

完整的按领域分组演示见 [`example/`](example)（num / datetime / regex / json / crypto /
storage / ext / identifier / log）。

## 变更记录

见 [CHANGELOG.md](CHANGELOG.md)。
