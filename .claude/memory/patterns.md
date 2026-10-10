# 项目特有代码模式

> 项目里**反直觉、容易踩坑、需要特定写法**的模式。AI 实现新功能前 Read 一遍。
>
> 本文件为**模板**，按项目实际填充。记「项目特有的」，不记通用语言 / 框架知识。

## 何时补充本文件

- 实现新功能时发现「这里有非显而易见的约定」
- 修 bug 时发现「这套用法是有原因的，下次别改」
- 做出「以后所有 X 都按这种写法」的统一决策
- 发现项目里隐藏的「地雷」（容易踩坑的写法）

## 不要写什么

- 通用语言 / 框架知识（那是官方文档的事）
- 显然的命名规范（在项目根 `CLAUDE.md` 里写）
- 一次性的实现细节（在源码里看就行）

## 格式模板

```markdown
## <模式标题>

**适用场景**：什么时候要用这个模式

**做法**：
\`\`\`<lang>
// 简短示例
\`\`\`

**为什么** / **替代方案为什么不行**：......

**对应位置**：`path/to/yyy.<ext>:NN`（参考实现）
```

## analysis_options.yaml 的 linter.rules 必须纯 map 形态

**适用场景**：在 `analysis_options.yaml` 里 disable 某条来自 `flutter_lints` include 的 lint 规则时。

**做法**：整块 rules 用 map 形态（启用项写 `rule: true`，禁用项写 `rule: false`），**禁止**列表项（`- rule`）与 map 条目混用。

**为什么**：YAML 同一 mapping 不允许混形态——混用触发 `parse_error`，且 analyzer 可能只部分应用配置，告警行号漂移难排查（crules-flutter 模板 0.4.1 的「map disable 扰动列表解析」即此坑，2026-09-12 本仓接入时实测复现）。

**对应位置**：`analysis_options.yaml:13`（豁免 constant_identifier_names 等 2 条的写法）；决策记录 `decisions/2026-09-12-crules-flutter-init-merge.md`

## SCREAMING_CASE 公开常量是既有风格，禁止顺手重命名

**适用场景**：改 `lib/regex/regex_constants.dart`、`lib/num/money_unit.dart` 等文件时。

**做法**：保持常量现名（SCREAMING_CASE）；`constant_identifier_names` / `non_constant_identifier_names` 已在 analysis_options.yaml 显式豁免。

**为什么**：40 个公开常量已按 SCREAMING_CASE 对外发布为公开 API，重命名=破坏性改动（CLAUDE.md §十红线）；发 2.0 时可再议统一重命名。

**对应位置**：`analysis_options.yaml:15`（豁免注释）；`lib/regex/regex_constants.dart`

## 模块头依赖标注与日志双轨定位行（2026-10-10 起）

**适用场景**：新增或修改 `lib/` 下工具模块的文件头注释时。

**做法**：在模块 description 块内（或紧邻处）补两类 `///` 行——`/// 依赖：<pkg>（平台插件——经原生通道，测试需打桩）` / `/// 依赖：<pkg>（纯 Dart）`；`log/` 与 `log_collector/` 额外带 `/// 定位：` 行互相指路（轻量打点 ↔ 完整采集管线）。

**为什么**：§十 类型B「重依赖要标注」的落地形式；消费者按全路径 import 单模块时，在模块头直接看到依赖成本（实测盘点：6 个模块带平台插件面，`log_collector/log_storage.dart:11` 依赖 `path_provider` 此前全库不可见）。

**对应位置**：`lib/storage/sp_util.dart:19`、`lib/file/file_utils.dart:23`、`lib/log/log.dart:12`、`lib/log_collector/log_collector_export.dart:8`（格式样例）
