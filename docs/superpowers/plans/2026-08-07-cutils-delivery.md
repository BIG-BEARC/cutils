# cutils 交付收尾实现计划 (Plan 5 of 5)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** 完成"可发布"的仓库内交付——`example/` 演示页、README、CHANGELOG（汇总全部破坏性变更）、版本号 `0.0.1→0.1.0`。**cashier 迁移后置**（涉另仓库，本计划不含）。

**Architecture:** Plan 1-4 已把 cutils 整理成结构清晰、API 统一、bug 全修、文档齐全的库；本计划只补"对外门面"：能跑给人看的 demo、README 索引、CHANGELOG 迁移说明。不改 lib/ 逻辑。

**Tech Stack:** Flutter widget（example demo）、Markdown（README/CHANGELOG）。

**参考:** [spec §8 / §9](../specs/2026-08-07-cutils-core-restructure-design.md)。基线：`dart analyze` = 50 info / 0 warning / 0 error；`flutter test` = 227/227。gate 不变（example 是独立子包，不影响根 analyze/test）。

---

## Task 1 — `example/` 演示页

把 Plan 1 中和掉的占位 `example/lib/main.dart` 扩成**按领域分组的可交互 demo**：
- `main.dart`：MaterialApp + 主页 ListView 列出 demo 分类（num / datetime / regex / json / crypto / storage / ext / identifier / log），每项跳转子页。
- 每个 demo 子页：用真实 cutils API（`import 'package:cutils/cutils.dart';` barrel）演示 2-4 个典型用法，展示输入→输出（如 `NumUtils.addDec(...)`、`DateTimeUtils.formatDate(now, format:...)`、`'x'.isEmail`、`CryptoUtils.encodeMd5(...)`）。
- 保持简洁——目的是"一看就懂怎么用"，不是完整功能展示。
- `example/` 是独立子包（`example/pubspec.yaml` 已 path-依赖 cutils）；确保 `cd example && flutter pub get` 通过、`flutter analyze`（example 内）零 error。
- **不改 lib/、不改根 test/**。

## Task 2 — README

替换占位 `README.md`：
- 定位（一行：通用 Flutter 工具库）、安装（pubspec `cutils` / git path）、最小用法（barrel import + 一例）。
- 模块地图索引（按领域一句话 + 链接到源码目录），呼应 CLAUDE.md 模块地图。
- 链接到 `example/` 与 CHANGELOG。
- 中文为主。

## Task 3 — CHANGELOG + 版本号

- `CHANGELOG.md`：按"## 0.1.0"汇总 Plan 1-4 全部**破坏性变更**（从 `git log master..HEAD` + 各 commit message 整理），分类列出：
  - 重构/路径：domain 合并改名、plugin 脚手架移除、barrel 新增。
  - API 风格：8 个单例→静态类（列名）。
  - 语义/行为：正则锚定与语义收紧、num/money 异常与精度、net 蓝牙/Windows、datetime DST/跨区/类型、timer 行为、isNullOrBlank/percentFormat/currencyFormat 等。
  - 删除：未用 lowercase 正则常量、url_utils/UrlUtils、bool_ext.then、TimelineInfo.weeks、scanner/serial/plugin 脚手架。
  - 重命名（带 deprecated 别名）：printJson→logJson、putObject→putJsonable。
  - 修复的高危 bug（简列：FlutterError 递归、log 轮转/Timer 泄漏、file 路径穿越/未 await、千分位负数等）。
- `pubspec.yaml`：版本 `0.0.1` → `0.1.0`（pre-1.0 破坏性）。

---

## 执行约束
- 不改 `lib/`、不改根 `test/`（本计划是门面交付）。
- example 是独立子包；改 example 后 `cd example && flutter pub get && flutter analyze` 需零 error（example 内）。
- 根 gate 不变：根 `dart analyze` 50/0/0、`flutter test` 227/227。
- 一任务一提交（不含 CLAUDE.md）。

## 完成标准
- [ ] `example/` 可跑的领域 demo（pub get + analyze 零 error）。
- [ ] README 替换占位、含定位/安装/模块索引/示例链接。
- [ ] CHANGELOG 汇总破坏性变更；pubspec `0.1.0`。
- [ ] 根 analyze 0 warning、227 测试全绿。

## 不在 Plan 5
迁移 cashier（saas-cashier 仓库的 import 与调用点更新）——后续单独进行。
