# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在此仓库中工作时提供指引。

> 本项目以【工具库风格】接入 **superpowers + dart-flutter** 两个插件协同工作：superpowers
> 管工程流程（设计→计划→TDD→评审→合并），dart-flutter 管 Dart/Flutter 技术正确性，本文件
> 钉死**提交策略、TDD 范围、公开 API 纪律**这两者都不替你决定的事。

## 这是什么

`cutils` 是一个 **Flutter 工具库**（普通包，非 plugin），核心价值是
一组**互相独立的 Dart 工具模块**。它作为依赖被其他 App 引用——**不是**可独立运行的
App。没有 `lib/main.dart`；`example/` 是演示用 demo。

> 通用的 Flutter/Dart 代码风格、主题与 UX 指南见
> [docs/FLUTTER_GUIDELINES.md](docs/FLUTTER_GUIDELINES.md)。本文件只覆盖**本仓库特有**
> 的内容。

**定位：工具库（普通包）**。下游可按全路径 `import 'package:cutils/<domain>/<module>.dart';`
引用各个模块，也可用顶层 barrel `import 'package:cutils/cutils.dart';` 一行导入。包内
**不含平台通道**（plugin 脚手架已移除）。因此本文件以**工具库纪律**为主（公开 API 稳定 +
TDD 全覆盖）；联邦接口 / 原生模块 / 双端对齐那套纪律不适用。

## 协作红线（最高优先级）

- **始终中文回复**：即使工具输出是英文也用中文转述
- **简洁直接**：先给可执行结论，少讲空话，不重复解释
- **禁止自动提交**：不自动 `git commit` / `git push`；只有用户发 `commit` / `push` / `提交`
  指令才开始提交流程（详见下「提交策略」）
- **先读后改**：改代码前先 Read 相关文件，基于现有上下文改，不凭猜测乱改
- **优先编辑现有文件**：非必要不新建
- **风险操作先确认**：`rm -rf`、`git reset --hard`、`git push -force`、改 CI、删分支等，先明确
  提醒再执行
- **方案先确认再实现**：非平凡改动（新模块、改公开签名、跨模块重构）先讨论方案、获用户确认，再写码
- **多方案走选项卡**：需用户在可枚举方案中取舍时，用 `AskUserQuestion` 呈现，不要手动加
  「自定义输入」（工具自带 Other 入口）

## 工作方式：superpowers + dart-flutter

| 层 | 谁 | 干什么 |
|---|---|---|
| 流程层 | superpowers | brainstorming → writing-plans → [worktree] → TDD → subagent → verification → review → finishing |
| 技术层 | dart-flutter | Dart/Flutter 任务怎么写对（测试 / 分析 / 模式匹配 / 序列化 / FFI） |
| 工具层 | dart-flutter Dart MCP + Stop hooks | 暴露 Dart 工具；会话停止自动 `dart-format` + `dart-analyze` |

**心智模型**：superpowers 说「做什么」（先写失败测试→看它失败→写最小实现），dart-flutter 说
「Dart 里怎么做」。两者分层，不冲突。每个任务开始前先检查是否有 skill 适用（superpowers 的 1%
规则：1% 可能适用就调用）。

**端到端链路**：

```
brainstorming → writing-plans → [using-git-worktrees] → test-driven-development / subagent-driven-development
→ verification-before-completion → requesting-code-review → (等待提交指令) → finishing-a-development-branch
```

| 步骤 | superpowers | dart-flutter 配合 |
|---|---|---|
| 1. 提需求 | `brainstorming`（HARD-GATE：未获设计批准禁止写码） | — |
| 2. 拆任务 | `writing-plans`（2–5 分钟粒度，带验证步骤） | — |
| 3. 写每个任务 | `test-driven-development`（red-green-refactor） | 测试→`dart-add-unit-test`；序列化→`flutter-implement-json-serialization`；模式匹配→`dart-use-pattern-matching`；主构造函数→`dart-use-primary-constructors` |
| 4. 派子代理 | `subagent-driven-development`（逐任务派发 + 两阶段评审） | — |
| 5. 会话停止 | — | **Stop hook 自动** `dart-format` + `dart-analyze` |
| 6. 声明完成前 | `verification-before-completion`（强制跑验证并贴输出） | `dart-run-static-analysis` |
| 7. 评审 | `requesting-code-review`（对照计划查） | — |
| 8. 提交 | ⚠️ **人工提交**（见下） | — |

## 提交策略（覆盖 superpowers 的自动提交）

> ⚠️ 这是与 superpowers 的唯一硬冲突，必须用本节压制。

- 本项目**遵守人工提交**：即使 superpowers 的 `test-driven-development` 要求「绿灯后 commit」、
  `brainstorming` 要求「设计通过后 commit」，本项目一律**不自动提交**。
- 依据：`using-superpowers` 内置优先级 = **用户指令 > skill > 默认行为**。本 CLAUDE.md 属于
  用户指令，优先级高于 skill。
- **只有**用户发送 `commit` / `push` / `提交` 指令，才执行 `git add → git commit → git push`
  完整流程，推送到远端才算完成。
- superpowers 的 TDD 流程中「commit」这一步，在本项目改为「标记任务完成、保留变更等用户审阅」。

## TDD 与验证

**TDD 范围（工具库导向：公开 API 全覆盖）**——cutils 大量纯函数，TDD 极契合：

| 代码类型 | 要求 | 测试形式 |
|---|---|---|
| 纯 Dart 工具 / 算法 / 格式化（`money_utils`、`num_utils`、`regex`、`encrypt`…） | **强制 red-green-refactor** | `package:test` 单测，边界值全覆盖 |
| 公开 API（public 类 / 方法 / 顶层函数 / 扩展） | **强制**，视为回归安全网 | 固定输入→固定输出 |
| 数据模型 / 序列化 | 强制 | 覆盖 `fromJson` / `toJson` 边界 |
| `log_collector` 等子系统 | 强制覆盖核心流程 | mock 存储 / 输出 |
| 既有无测试代码 | 改动前先补「表征测试」锁现状，再改 | — |

> superpowers 会**删掉先于测试写的代码**。公开 API 尤其要先用测试钉死行为，再动实现。

**验证纪律**——声明任何「完成 / 修复 / 通过」之前，必须运行验证命令并**贴出输出**
（superpowers `verification-before-completion`）：

- `dart analyze`（**零 warning** 才算过；warning 视作回归——见「常用命令」末尾的既有要求）
- `flutter test`（相关测试全绿）
- 改了插件本体可见行为时 `cd example && flutter run` 验证
- 验证范围未覆盖的部分**明确告知用户**，不谎报

## 公开 API 稳定性（工具库最重要纪律）

详见「架构 > 一个包里并存着两件不相干的事」——下游直接按路径 import 每个 util，所以
**每个公开符号都是已发布接口**。在此基础上叠加：

- **保持签名稳定**：不随意改名 / 改参数 / 改返回类型；破坏性改动必须升主版本号 + 写迁移说明
- **新增优先于修改**：加新模块 / 新可选参数是安全的；改现有签名是危险的
- **避免破坏性重命名**：已有公开类 / 方法 / 顶层函数改名 = 破坏下游，要改先讨论影响
- **不 re-export 污染**：`lib/cutils.dart` 按既有策略决定是否 re-export 子模块，不擅自改导出面

## 常用命令

```bash
flutter pub get                       # 拉取依赖（本包使用了平台插件）
dart analyze                          # 静态分析（基于 package:flutter_lints）
dart fix --apply                      # 自动修复机械性的 lint / 分析问题
dart format                           # 每次改动后格式化

flutter analyze                       # 代码检查
flutter test                          # 跑全部测试（package:test + mocktail）
flutter test test/file/file_utils_test.dart        # 只跑单个文件
flutter test --plain-name "barrel 导出关键公开符号"  # 按名字跑单个测试

cd example && flutter run             # 通过 demo app 验证插件接口
```

最近的几次提交专门在清理分析器告警（"消除错误警告"）。每次结束工作前都应跑一遍
`dart analyze`，任何告警都视作回归。

## 架构

### 纯工具库（普通包，无平台通道）

`cutils` 是**纯工具库**。`lib/` 下按领域分目录，每个目录一组工具；顶层
[lib/cutils.dart](lib/cutils.dart) 是 **barrel**，统一 re-export 全部核心模块——消费方可
`import 'package:cutils/cutils.dart';` 一行导入，也可按全路径 `import 'package:cutils/num/money_utils.dart';`
按需导入单个模块。

因为下游直接按路径 import 每个 util，所以**每个 util 的公开 API 实际上都是对外发布的接口**
——保持签名稳定，避免破坏性的重命名（详见「公开 API 稳定性」）。

> 历史：本包原是 `flutter create --template=plugin` 生成的 plugin（`Cutils`/method_channel/
> android/ios，仅 `getPlatformVersion()`），已在本轮重组中移除。

### 模块地图（按领域划分）

- `num/` —— 金额 / 高精度计算（`money_utils`、`money_unit`、`num_utils`），基于 `decimal`。
- `ext/` —— 内置类型扩展（`string_ext`、`int_ext`、`double_ext`、`bool_ext`、`object_ext`、
  `widget_ext`），`ext_fun.dart` 是 barrel。
- `datetime/` —— 日期时间（`date_utils` 的 **`DateTimeUtils`**、`timeline_util`、`timer_util`
  及 zh/en 本地化信息）。⚠️ 类名是 `DateTimeUtils`，已避开 Flutter SDK 的 `DateUtils` 同名。
- `regex/`、`json/` —— 正则 / JSON。
- `crypto/` —— 加解密（**`CryptoUtils`**，用 `crypto` 包；md5/hmac/base64/xor）。
- `file/`、`storage/`（SharedPreferences 的 `SpUtil`）、`net/`（connectivity）。
- `system/` —— 设备 / 包信息、键盘、系统工具。
- `ui/` —— Flutter 框架 UI 工具（`calculate_utils` 文本测量、`image_utils`）。
- `event/`（事件总线）、`identifier/`（`random_utils`、`uuid_utils`）。
- `log/`（`logger` 包薄封装）vs `log_collector/`（完整日志收集子系统，见下）。
- 顶层 barrel `lib/cutils.dart`。

> 本轮重组变更：合并 `date/`+`time/`→`datetime/`；`encrypt/`→`crypto/`；`sp/`→`storage/`；
> 解散 `utils/` grab-bag → `event/`+`ui/`+`identifier/`；`text/` 拆入 `ui/`+`ext/`；
> 移除 plugin 脚手架与 `scanner/`、`serial_util`（硬件延期到独立子包 `cutils_pos`）。

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
- **测试**使用 `package:test` / `flutter_test` 配合 `mocktail`；平台依赖（如 path_provider）
  通过 `MockPathProviderPlatform` 打桩（见
  [test/file/file_utils_test.dart](test/file/file_utils_test.dart)）；barrel 解析见
  [test/cutils_barrel_test.dart](test/cutils_barrel_test.dart)。

## 后台 agent 完成后必须展示 diff

后台 agent 的中间 Edit/Write 步骤主对话不可见。后台 agent 完成、汇总给用户前，**主控必须主动**：

1. `git status`——列出新增 / 修改 / 删除文件清单
2. `git diff`（含未暂存）和 `git diff --staged`——展示完整变更；过长按文件分批，先给「哪些文件
   改了」概览
3. 把 agent 自报「做了什么」与实际 diff **逐项对照**，不一致或遗漏要指出

> 这是后台模式下用户审阅代码的唯一入口，禁止跳过、禁止只贴 agent 摘要。配合 superpowers 的
> `subagent-driven-development` 尤其重要。

## Plugin / Dart skill 速查

| 场景 | 调用 dart-flutter skill |
|---|---|
| 写 / 补单测 | `dart-add-unit-test` |
| 跑静态分析（零 warning） | `dart-run-static-analysis` |
| 机械性 lint 自动修 | 配合 `dart fix --apply` |
| 收集测试覆盖率 | `dart-collect-coverage` |
| 包版本冲突 | `dart-resolve-package-conflicts` |
| switch 表达式 / 模式匹配 | `dart-use-pattern-matching` |
| 主构造函数 | `dart-use-primary-constructors` |
| 迁移到 `package:checks` | `dart-migrate-to-checks-package` |
| 模型序列化 | `flutter-implement-json-serialization` |
| 生成 mock（unit test） | `dart-generate-test-mocks` |
| 修运行时错误（配合 LSP / 热重载） | `dart-fix-runtime-errors` |
