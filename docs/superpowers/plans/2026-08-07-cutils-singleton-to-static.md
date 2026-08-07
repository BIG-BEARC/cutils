# cutils 单例→静态类转换实现计划 (Plan 2 of 5)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development to implement task-by-task. Steps use checkbox (`- [ ]`).

**Goal:** 把 8 个无状态工具单例转为静态类（spec §4 + §11 D3），消除 `final xUtils = XUtils()` + `factory` 样板，调用点 `xUtils.foo()`→`XUtils.foo()`。7 个有状态单例保留实例。

**Architecture:** 无状态工具 = 纯函数集合 → 静态类 + 静态方法；`Random`/`_uuid`/`_cache` 等"内部状态"改静态字段。有状态工具（SpUtil/LogCollector/EventBusUtil/NetUtil/DeviceInfoUtil/PackageInfoUtil/LoggerUtils）不动。本计划不改任何方法体逻辑（bug 在 Plan 3/4）。

**Tech Stack:** Dart 3.6+ / Flutter ≥3.3。macOS（BSD `sed -i ''`，注意 `\b` 在本机 sed 不生效，用 `[[:<:]]`/`[[:>:]]` 或精确串）。

**参考:** [spec §4 / §11 D2-D3](../specs/2026-08-07-cutils-core-restructure-design.md)。基线：`dart analyze` = 56 info / 0 warning / 0 error；`flutter test` = 9/9。

---

## 转换算法（两种变体）

### 变体 A：纯无状态（NumUtils / CryptoUtils / JsonUtils / UrlUtils / KeyBoardUtils）

前：
```dart
final numUtils = NumUtils();
class NumUtils {
  NumUtils._();
  static final NumUtils _ins = NumUtils._();
  factory NumUtils() => _ins;
  bool isNum(String? s) { ... }
}
```
后（删全局实例、删 factory、删 `_ins`、方法加 `static`）：
```dart
class NumUtils {
  NumUtils._();
  static bool isNum(String? s) { ... }
}
```

### 变体 B：内部状态改静态字段（RandomUtils / UUIDUtils）

前：
```dart
final randomUtils = RandomUtils();
class RandomUtils {
  RandomUtils._();
  static final RandomUtils _instance = RandomUtils._();
  factory RandomUtils() => _instance;
  final Random _random = Random();          // 实例字段
  String randomString(int length) { ... 用 _random ... }
}
```
后（`_random` 改 `static`，方法加 `static`）：
```dart
class RandomUtils {
  RandomUtils._();
  static final Random _random = Random();
  static String randomString(int length) { ... }
}
```
（`UUIDUtils` 同理：`Uuid _uuid` 与 `Map _cache` 改 `static`。）

### 调用点改写
`xUtils.foo(...)` → `XUtils.foo(...)`。用 grep 精确定位每个 util 的调用点（包内 lib/example/test），逐个改。全局实例名（如 `encryptUtils`/`uuidUtil`/`keyBoardUtils` 等不一致命名）随转换消除。

---

## 任务清单

### Task 1: 5 个 leaf 工具转静态（0 外部调用点）
**目标:** `CryptoUtils`、`RandomUtils`、`UUIDUtils`、`UrlUtils`、`KeyBoardUtils`——这 5 个无外部调用点，只改自身（变体 A/B），无需改调用点。

**Files:** `lib/crypto/crypto_utils.dart`、`lib/identifier/random_utils.dart`、`lib/identifier/uuid_utils.dart`、`lib/net/url_utils.dart`、`lib/system/keyboard_util.dart`

- [ ] **Step 1:** 对每个文件应用变体 A（CryptoUtils/UrlUtils/KeyBoardUtils）或变体 B（RandomUtils/UUIDUtils）：删 `final xxxUtil[s] = ...` 全局行；删 `factory` + `_ins`/`_instance` 静态实例；构造 `Class._();` 保留（私有，防实例化）；所有公开方法加 `static`；RandomUtils 的 `_random`、UUIDUtils 的 `_uuid`/`_cache` 改 `static`。
- [ ] **Step 2:** `grep -rn -E "\b(encryptUtils|randomUtils|uuidUtil|urlUtils|keyBoardUtils)\." lib example test` 确认零调用点残留（这 5 个本就 leaf）。
- [ ] **Step 3:** `dart analyze`（0 error/warning，info ≤ 56）+ `flutter test`（9/9）。
- [ ] **Step 4:** `git add` 这 5 文件（不含 CLAUDE.md）+ commit `refactor: 5 个 leaf 工具单例→静态类（Crypto/Random/UUID/Url/KeyBoard）`。

### Task 2: NumUtils 转静态（1 个外部调用点）
**Files:** `lib/num/num_utils.dart` + 调用点（grep `numUtils.`）

- [ ] **Step 1:** 应用变体 A 到 `NumUtils`。
- [ ] **Step 2:** `grep -rn "\bnumUtils\." lib example test`，把每个 `numUtils.foo(...)` → `NumUtils.foo(...)`。
- [ ] **Step 3:** `dart analyze` + `flutter test`（9/9）。
- [ ] **Step 4:** commit `refactor: NumUtils 单例→静态类`（不含 CLAUDE.md）。

### Task 3: JsonUtils 转静态（2 个外部调用点）
**Files:** `lib/json/json_utils.dart` + 调用点（grep `jsonUtil.`）

- [ ] **Step 1:** 应用变体 A 到 `JsonUtils`（全局实例名是 `jsonUtil`，单数）。
- [ ] **Step 2:** `grep -rn "\bjsonUtil\." lib example test`，`jsonUtil.foo(...)` → `JsonUtils.foo(...)`。
- [ ] **Step 3:** `dart analyze` + `flutter test`（9/9）。
- [ ] **Step 4:** commit `refactor: JsonUtils 单例→静态类`（不含 CLAUDE.md）。

### Task 4: DateTimeUtils 转静态（~14 调用点 + 测试）
**Files:** `lib/datetime/date_utils.dart`、`lib/datetime/timeline_util.dart`（主要调用点）、`test/datetime/date_time_utils_test.dart`

- [ ] **Step 1:** 应用变体 A 到 `DateTimeUtils`（删 `final dateTimeUtils = ...`、factory、`_instance`；方法加 `static`）。**注意**：`date_utils.dart` 里 `static final DateTimeUtils _instance` 与各方法间可能有内部 `this` 引用——静态化后方法体内不能再用 `this`/实例字段；该类本无状态，确认无误。
- [ ] **Step 2:** 改写所有调用点：`grep -rn "\bdateTimeUtils\." lib example test`，`dateTimeUtils.foo(...)` → `DateTimeUtils.foo(...)`。重点：`timeline_util.dart`（约 11 处）、`test/datetime/date_time_utils_test.dart:8`（`dateTimeUtils.formatDate` → `DateTimeUtils.formatDate`）。
- [ ] **Step 3:** `dart analyze`（0 error/warning）+ `flutter test`（9/9——date_time_utils_test 仍绿，因其只改调用形式）。
- [ ] **Step 4:** commit `refactor: DateTimeUtils 单例→静态类`（不含 CLAUDE.md）。

### Task 5: 全量收尾验证
- [ ] **Step 1:** `grep -rn -E "\b(numUtils|dateTimeUtils|encryptUtils|jsonUtil|randomUtils|uuidUtil|urlUtils|keyBoardUtils)\." lib example test` → 应**全零**（8 个全局实例已不存在）。
- [ ] **Step 2:** `dart format` + `dart fix --apply`（机械整理）。
- [ ] **Step 3:** `dart analyze`（0 error/warning，info ≤ 56）+ `flutter test`（9/9）。
- [ ] **Step 4:** 若有 format/fix 改动，commit `refactor: Plan 2 收尾——format/fix`（不含 CLAUDE.md）。

---

## 完成标准
- [ ] 8 个无状态工具全部为静态类，全局实例变量全部消失（grep 全零）。
- [ ] 7 个有状态单例（SpUtil/LogCollector/EventBusUtil/NetUtil/DeviceInfoUtil/PackageInfoUtil/LoggerUtils）**未动**，仍是实例单例。
- [ ] `dart analyze` 0 error/0 warning，info ≤ 56；`flutter test` 9/9。
- [ ] 调用点全部改 `XUtils.foo()` 形式；`date_time_utils_test` 用 `DateTimeUtils.formatDate`。

## 不在 Plan 2
- bug 修复（Plan 3/4）、单测全覆盖（Plan 3/4）、example/README（Plan 5）、迁移 cashier（Plan 5）。
- 有状态单例的 init 竞态等 bug（Plan 3，如 sp/logCollector/deviceInfo 的 init）。
