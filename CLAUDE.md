# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在此仓库中工作时提供指引。

## 这是什么

`cutils` 是一个 **Flutter 插件包**（含 Android + iOS 原生脚手架），但它的核心价值
是一组**互相独立的 Dart 工具模块**。它作为依赖被其他 App 引用——**不是**可独立运行的
App。没有 `lib/main.dart`；`example/` 仅为演示插件接口而存在。

> 通用的 Flutter/Dart 代码风格、主题与 UX 指南见
> [docs/FLUTTER_GUIDELINES.md](docs/FLUTTER_GUIDELINES.md)。本文件只覆盖**本仓库特有**
> 的内容。

## 常用命令

```bash
flutter pub get                       # 拉取依赖（本包使用了平台插件）
dart analyze                          # 静态分析（基于 package:flutter_lints）
dart fix --apply                      # 自动修复机械性的 lint / 分析问题
dart format                           # 每次改动后格式化

flutter analyze                       # 代码检查
flutter test                          # 跑全部测试（package:test + mocktail）
flutter test test/file/file_utils_test.dart        # 只跑单个文件
flutter test --plain-name "getPlatformVersion"     # 按名字跑单个测试

cd example && flutter run             # 通过 demo app 验证插件接口
```

最近的几次提交专门在清理分析器告警（"消除错误警告"）。每次结束工作前都应跑一遍
`dart analyze`，任何告警都视作回归。

## 架构

### 一个包里并存着两件不相干的事

1. **插件脚手架**（`flutter create --template=plugin` 生成的样板）：
   [lib/cutils.dart](lib/cutils.dart) 只定义了 `class Cutils`，且仅暴露
   `getPlatformVersion()`。它沿联邦化接口流转
   （`cutils_platform_interface.dart` → `cutils_method_channel.dart`，即 `'cutils'`
   MethodChannel）到原生层 `CutilsPlugin.kt` / `CutilsPlugin.swift`。基本不需要改动。

2. **`lib/<domain>/` 下的工具模块**——本包真正的价值所在。每个模块都**自成一体、按完整
   路径导入**：`lib/cutils.dart` **并不会 re-export** 它们。消费方写作例如
   `import 'package:cutils/num/money_utils.dart';`。

因为下游 App 都是直接按路径 import 每个 util 文件，所以**每个 util 的公开 API 实际上
都是对外发布的接口**——保持签名稳定，避免破坏性的重命名。

### 模块地图（按领域划分）

- `num/` —— 金额 / 高精度计算（`money_utils`、`money_unit`、`num_utils`），基于
  `decimal` 实现不丢精度的 BigDecimal 式运算。
- `ext/` —— 对内置类型的扩展（`string_ext`、`int_ext`、`double_ext`、`bool_ext`、
  `object_ext`、`widget_ext`）以及 `ext_fun.dart`。
- `time/` vs `date/` —— **两件不同的事**：`time/` 是人性化时间轴与计时器（按 git 历史，
  `timeline_util` 最近刚被拆分出来），`date/` 是格式化 / 解析。不要混为一谈。
- `log/` vs `log_collector/` —— **不同**：`log/` 是对 `logger` 包的薄封装；
  `log_collector/` 是一整套子系统（见下）。
- `system/` —— 设备 / 包信息、键盘、系统工具。`serial_util.dart` 目前**整文件被注释掉**
  （封装 `flutter_libserialport`，用于 Windows 串口电子秤）——复活它之前要先恢复依赖。
- `scanner/` —— `ScanMonitor`，一个捕获扫码枪 / 键盘模拟输入的 widget。标注为
  **待验证**，且引入了 Windows 电子秤相关依赖（`rxdart`、`dartx`）；依赖其行为前先验证。
- 其余：`encrypt/`、`file/`、`json/`、`net/`、`regex/`、`sp/`（SharedPreferences）、
  `text/`、`utils/`（event_bus、image、random、uuid）。

### `log_collector/` 子系统

最复杂的模块——完整说明见 [lib/log_collector/README.md](lib/log_collector/README.md)。
数据流：

`LogInterceptor`（来源：debugPrint / 异常 / 文件）→ `LogCollector` 单例（入队后按 level
+ tag 过滤）→ `LogStorage`（内存 + 文件）**以及** `LogOutput`（控制台 / 文件 / 网络 /
批量）。

- 入口是顶层单例 `logCollector`（= `LogCollector.instance`）；`LogCollectorHelper`
  提供 `quickInitialize()` 以及按级别的辅助方法。
- `initialize()` 幂等（由 `_isInitialized` 守卫）；`dispose()` 在销毁前会先排空队列。
- 整个模块通过 `log_collector_export.dart` 统一导出；import 路径为
  `package:cutils/log_collector/...`（已统一修正，原为从宿主 App 抽出时遗留的
  `package:cashier/...`）。

## 本仓库特有的约定

- **import 分组头注释** —— 现有文件以 `// Dart imports:`、`// Flutter imports:`、
  `// Package imports:` 分块开头。新增文件时沿用该顺序。
- **作者文档块** —— 较大的模块带有 `/// * @Author: chuxiong ...` 头部。新增模块时遵循
  该写法。
- **业务逻辑注释用中文** —— 同一文件内保持一致，不要中英混用。
- **测试**使用 `package:test` / `flutter_test` 配合 `mocktail`；MethodChannel 通过
  `setMockMethodCallHandler` 打桩（见
  [test/cutils_method_channel_test.dart](test/cutils_method_channel_test.dart)）。
