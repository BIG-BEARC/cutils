# cutils Cleanup + Restructure Implementation Plan (Plan 1 of 5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `cutils` 从 plugin 包清理、降级为普通包，并完成目录重组（合并/改名/解散/barrel），交付一个 `dart analyze` + `flutter test` 全绿的新结构。

**Architecture:** 删除死代码、死依赖与 plugin 脚手架；按 spec §3 的目标结构做文件移动与改名（date+time→datetime、encrypt→crypto、sp→storage、解散 utils/、text→ui+ext）；新增顶层 `lib/cutils.dart` barrel 统一导出。本计划**不改 API 行为**（单例→静态类转换、bug 修复、新测试、文档/示例、迁移 cashier 均在后续 Plan 2–5）。

**Tech Stack:** Dart 3.6+ / Flutter ≥3.3、`package:flutter_lints`、`package:test`+`mocktail`。macOS 环境（BSD `sed -i ''`）。

**参考 spec:** [docs/superpowers/specs/2026-08-07-cutils-core-restructure-design.md](../specs/2026-08-07-cutils-core-restructure-design.md) §3/§5/§10 阶段 1–2。

**约定:**
- 每个任务结束必须 `dart analyze` 零告警；涉及测试时 `flutter test` 全绿。
- 文件移动用 `git mv`（保留历史）。import 改写用 `sed -i ''`（macOS BSD）。
- 内部自引用清单（重组需同步改）: `file_utils`→date_utils/log、`json_utils`→log、`net_util`→log、`num_utils`→ext_fun、`sp_util`→json_utils/log、`device_info_util`→log、`system_utils`→ext_fun/log、`timeline_util`→date_utils。

---

## Task 0: 基线验证

**Files:** 无改动

- [ ] **Step 1: 确认起始状态可分析/可测**

Run:
```bash
cd /Users/chuxiong/AndroidStudioProjects/flutter/cutils
flutter pub get
dart analyze
flutter test
```
Expected: `dart analyze` 仅有已知告警或无告警；`flutter test` 3 个测试通过（cutils_test、cutils_method_channel_test、file_utils_test）。记录告警数作为基线。若已存在报错，先记下（后续任务不应新增）。

- [ ] **Step 2: 建立重组分支**

Run:
```bash
git checkout -b refactor/cutils-cleanup-restructure
```
Expected: 切到新分支。

---

## Task 1: 删除死代码

**Files:**
- Delete: `lib/system/serial_util.dart`（278 行全注释，硬件延期）
- Delete: `lib/scanner/`（整个目录，scan_monitor 延期到 cutils_pos）
- Move: `lib/log_collector/example/usage_example.dart` → `example/lib/log_collector_usage_example.dart`（不该在 lib/ 下编译）

- [ ] **Step 1: 删 serial_util 与 scanner**

Run:
```bash
git rm lib/system/serial_util.dart
git rm -r lib/scanner
```
Expected: 两个路径删除。

- [ ] **Step 2: 移出 usage_example**

Run:
```bash
mkdir -p example/lib
git mv lib/log_collector/example/usage_example.dart example/lib/log_collector_usage_example.dart
# 若空目录残留：
rmdir lib/log_collector/example 2>/dev/null || true
```
Expected: 文件迁到 example/，lib/ 下不再有 example/。

- [ ] **Step 3: 验证**

Run:
```bash
dart analyze
```
Expected: 无新增告警（scanner/serial 已删，相关引用本来为零）。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: 删除硬件死代码(serial_util/scanner)，移出 usage_example"
```

---

## Task 2: 删除 plugin 脚手架

**Files:**
- Delete: `lib/cutils_method_channel.dart`、`lib/cutils_platform_interface.dart`
- Delete: `android/`（整目录）、`ios/`（整目录）
- Delete: `test/cutils_test.dart`、`test/cutils_method_channel_test.dart`
- Modify: `lib/cutils.dart`（清空 plugin `Cutils` 类；本任务先置为占位，Task 10 填 barrel）

> 注: `lib/cutils.dart` 当前内容是 `class Cutils { Future<String?> getPlatformVersion() ... }`，依赖即将删除的 `cutils_platform_interface.dart`。

- [ ] **Step 1: 删 method_channel / platform_interface**

Run:
```bash
git rm lib/cutils_method_channel.dart lib/cutils_platform_interface.dart
```

- [ ] **Step 2: 删 android/ 与 ios/ 原生目录**

Run:
```bash
git rm -r android ios
```
Expected: 两个平台目录删除。

- [ ] **Step 3: 删脚手架测试**

Run:
```bash
git rm test/cutils_test.dart test/cutils_method_channel_test.dart
```

- [ ] **Step 4: 中和 example/lib/main.dart（去掉对 Cutils 的依赖）**

`example/lib/main.dart` 当前用 `Cutils().getPlatformVersion()`，删类后会断。完整演示页在 Plan 5 重写；本任务先把它换成不依赖 Cutils 的最小占位。写入 `example/lib/main.dart`：
```dart
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('cutils example — 演示页见 Plan 5')),
      ),
    );
  }
}
```

- [ ] **Step 5: 清空 cutils.dart 为占位（Task 10 填 barrel）**

写入 `lib/cutils.dart`：
```dart
// cutils 顶层 barrel —— 详见 Task 10。
library;
```

- [ ] **Step 6: 验证**

Run:
```bash
dart analyze
```
Expected: 无未解析引用（确认 lib/ 无残留 import `cutils_method_channel`/`cutils_platform_interface`/`plugin_platform_interface`）。若有，grep 出并删除。

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: 删除 plugin 脚手架(method_channel/platform_interface/android/ios)与脚手架测试，中和 example"
```

---

## Task 3: pubspec 清理

**Files:**
- Modify: `pubspec.yaml`（删 `flutter.plugin` 段第 56–62 行；删 5 个死依赖；订正 dartx 注释）

- [ ] **Step 1: 删 flutter.plugin 段**

用编辑器删除 `pubspec.yaml` 中如下整段（约第 56–62 行）：
```yaml
  plugin:
    platforms:
      android:
        package: com.cx.cutils
        pluginClass: CutilsPlugin
      ios:
        pluginClass: CutilsPlugin
```
保留其上的 `flutter:` 行与 `uses-material-design` 等（若存在）。

- [ ] **Step 2: 删死依赖**

从 `dependencies:` 删除这 5 行：
```yaml
  flutter_libserialport: ^0.4.0
  rxdart: ^0.27.7 #反应式编程 windows电子秤需要
  dartx: ^1.2.0 #windows电子秤需要      # ← dartx 保留！仅删其错误注释并改注释
  network_info_plus: ^7.0.0
  permission_handler: ^10.2.0
  plugin_platform_interface: ^2.0.2
```
**订正**: `dartx` **保留**（`file/file_utils.dart` 真实使用），把其注释改为 `dartx: ^1.2.0 #file_utils 的 isNullOrEmpty/.filter 使用`。删除 `flutter_libserialport`、`rxdart`、`network_info_plus`、`permission_handler`、`plugin_platform_interface`。

- [ ] **Step 3: 验证 pubspec 可解析**

Run:
```bash
flutter pub get
```
Expected: 无依赖解析错误。

- [ ] **Step 4: 验证分析**

Run:
```bash
dart analyze
```
Expected: 无 `plugin_platform_interface` 相关未解析引用（Task 2 已删脚手架，应无残留）。

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml example/pubspec.lock
git commit -m "refactor: pubspec 删除死依赖与 plugin 段，订正 dartx 注释"
```

---

## Task 4: 合并 date/ + time/ → datetime/

**Files:**
- Move: `lib/date/*` 与 `lib/time/*` → `lib/datetime/`
- Modify: `lib/file/file_utils.dart`、`lib/datetime/timeline_util.dart`（改 import 路径 `date/`→`datetime/`）

- [ ] **Step 1: 移动文件**

Run:
```bash
git mkdir -p lib/datetime 2>/dev/null || mkdir -p lib/datetime
git mv lib/date/date_utils.dart     lib/datetime/date_utils.dart
git mv lib/date/data_formats.dart   lib/datetime/data_formats.dart
git mv lib/time/timeline_util.dart  lib/datetime/timeline_util.dart
git mv lib/time/timer_util.dart     lib/datetime/timer_util.dart
git mv lib/time/abs_time_info.dart  lib/datetime/abs_time_info.dart
git mv lib/time/day_format.dart     lib/datetime/day_format.dart
git mv lib/time/zh_info.dart        lib/datetime/zh_info.dart
git mv lib/time/zh_normal_info.dart lib/datetime/zh_normal_info.dart
git mv lib/time/en_info.dart        lib/datetime/en_info.dart
git mv lib/time/en_normal_info.dart lib/datetime/en_normal_info.dart
rmdir lib/date lib/time
```
Expected: `lib/datetime/` 含 10 文件，`lib/date`、`lib/time` 消失。

- [ ] **Step 2: 改写内部 import（date/ → datetime/）**

Run:
```bash
grep -rl "package:cutils/date/" lib | while read f; do
  sed -i '' 's#package:cutils/date/#package:cutils/datetime/#g' "$f"
done
```
Expected: `file_utils.dart`、`timeline_util.dart` 的 `package:cutils/date/...` → `package:cutils/datetime/...`。

- [ ] **Step 3: 验证**

Run:
```bash
dart analyze
```
Expected: 无 `uri_does_not_exist`（确认 `lib/date`/`lib/time` 无残留引用）。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: 合并 date/ + time/ → datetime/"
```

---

## Task 5: DateUtils → DateTimeUtils（避开 Flutter SDK 同名）

**Files:**
- Modify: `lib/datetime/date_utils.dart`（类名 + 全局单例名）
- Modify: 所有引用 `DateUtils`/`dateUtils` 处（grep 定位）

> 原因: Flutter `package:flutter/material.dart` 已有 `DateUtils`，撞名。本任务仅改名，**保留单例形态**（单例→静态在 Plan 2）。

- [ ] **Step 1: 写一条验证用测试（锁定类名存在）**

创建 `test/datetime/date_time_utils_test.dart`：
```dart
import 'package:cutils/datetime/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DateTimeUtils 类存在且可格式化', () {
    final dt = DateTime(2026, 8, 7, 9, 30, 5);
    expect(dateTimeUtils.formatDate(dt, 'yyyy-MM-dd HH:mm:ss'),
        '2026-08-07 09:30:05');
  });
}
```
> 注: 本测试仅锁定"类改名后仍可调用"，**故意不含 `SSS` 毫秒断言**——SSS 在 ms<100 有已知 bug（spec §6.1），其回归测试在 Plan 3 补，避免在此耦合未修行为。

- [ ] **Step 2: 运行测试，预期 FAIL（类仍叫 DateUtils）**

Run:
```bash
flutter test test/datetime/date_time_utils_test.dart
```
Expected: FAIL（`DateTimeUtils` 未定义 / `dateTimeUtils` 未定义）。

- [ ] **Step 3: 重命名类与全局**

在 `lib/datetime/date_utils.dart` 中：
- `class DateUtils` → `class DateTimeUtils`
- `final dateUtils = DateUtils();` → `final dateTimeUtils = DateTimeUtils();`
- 工厂/构造里的 `DateUtils` → `DateTimeUtils`

Run（自动替换文件内剩余 `DateUtils`/`dateUtils`）:
```bash
sed -i '' 's/\bDateUtils\b/DateTimeUtils/g; s/\bdateUtils\b/dateTimeUtils/g' lib/datetime/date_utils.dart
```

- [ ] **Step 4: 全仓改写外部引用**

Run:
```bash
grep -rl -E "\bDateUtils\b|\bdateUtils\b" lib example | while read f; do
  sed -i '' 's/\bDateUtils\b/DateTimeUtils/g; s/\bdateUtils\b/dateTimeUtils/g' "$f"
done
```
Expected: `timeline_util.dart`（用 dateUtils）等同步更新。

- [ ] **Step 5: 运行测试，预期 PASS**

Run:
```bash
flutter test test/datetime/date_time_utils_test.dart
```
Expected: PASS。

- [ ] **Step 6: 全量分析**

Run:
```bash
dart analyze
```
Expected: 无 `undefined_name`/`undefined_class` 残留。

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: DateUtils→DateTimeUtils 避 Flutter SDK 同名"
```

---

## Task 6: 解散 utils/ grab-bag

**Files:**
- Move: `lib/utils/event_bus_util.dart` → `lib/event/event_bus_util.dart`
- Move: `lib/utils/image_utils.dart` → `lib/ui/image_utils.dart`
- Move: `lib/utils/random_utils.dart` → `lib/identifier/random_utils.dart`
- Move: `lib/utils/uuid_utils.dart` → `lib/identifier/uuid_utils.dart`
- Delete: `lib/utils/`（空目录）

- [ ] **Step 1: 建目录并移动**

Run:
```bash
mkdir -p lib/event lib/ui lib/identifier
git mv lib/utils/event_bus_util.dart lib/event/event_bus_util.dart
git mv lib/utils/image_utils.dart     lib/ui/image_utils.dart
git mv lib/utils/random_utils.dart    lib/identifier/random_utils.dart
git mv lib/utils/uuid_utils.dart      lib/identifier/uuid_utils.dart
rmdir lib/utils
```

- [ ] **Step 2: 改写外部 import**

Run:
```bash
grep -rl -E "package:cutils/utils/(event_bus_util|image_utils|random_utils|uuid_utils)" lib example | while read f; do
  sed -i '' \
    -e 's#package:cutils/utils/event_bus_util#package:cutils/event/event_bus_util#' \
    -e 's#package:cutils/utils/image_utils#package:cutils/ui/image_utils#' \
    -e 's#package:cutils/utils/random_utils#package:cutils/identifier/random_utils#' \
    -e 's#package:cutils/utils/uuid_utils#package:cutils/identifier/uuid_utils#' \
    "$f"
done
```
Expected: 无残留 `package:cutils/utils/`。

- [ ] **Step 3: 验证**

Run:
```bash
dart analyze
flutter test
```
Expected: 无 `uri_does_not_exist`；测试全绿。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: 解散 utils/ → event/ ui/ identifier/"
```

---

## Task 7: text/ 拆分（calculate→ui，谓词并入 string_ext，删除 text_utils）

**Files:**
- Move: `lib/text/calculate_utils.dart` → `lib/ui/calculate_utils.dart`
- Modify: `lib/ext/string_ext.dart`（吸收 `text/text_utils.dart` 的字符串方法为扩展）
- Delete: `lib/text/text_utils.dart`、`lib/text/`（空目录）

> 本任务**仅迁移方法签名**，不修 bug（reverse/abbreviate 等的正确性修复在 Plan 3/4）。目标是消除 `text_utils` 与 `string_ext` 的重复入口。

- [ ] **Step 1: 迁移 calculate_utils**

Run:
```bash
git mv lib/text/calculate_utils.dart lib/ui/calculate_utils.dart
```
改引用：
```bash
grep -rl "package:cutils/text/calculate_utils" lib example | while read f; do
  sed -i '' 's#package:cutils/text/calculate_utils#package:cutils/ui/calculate_utils#' "$f"
done
```

- [ ] **Step 2: 审计 text_utils 方法 vs string_ext**

Run:
```bash
echo "=== text_utils 公开方法 ==="; grep -nE "^\s+(bool|String|int|double|void|dynamic) [a-zA-Z]+\(" lib/text/text_utils.dart
echo "=== string_ext 已有扩展 ==="; grep -nE "^\s*(bool|String|int|double) get [a-zA-Z]+|^\s*extension" lib/ext/string_ext.dart
```
逐方法比对：`text_utils` 中**已在 `string_ext` 存在等价扩展**的（如 `isEmpty`/`isNotEmpty`/`startsWith`）→ 跳过；**string_ext 没有**的（如 `reverse`、`abbreviate`、`formatDoubleComma3`、`hideNumber`、`replace`、`split` 等）→ 加到 `string_ext.dart` 作 `extension StringX on String?`（或现有扩展）的方法，方法体原样搬入（不改逻辑）。

- [ ] **Step 3: 把独有方法搬进 string_ext**

在 `lib/ext/string_ext.dart` 现有 `extension ... on String?`（或新建 `extension StringTextExt on String?`）末尾，加入 Step 2 判定为"独有"的方法，改为扩展形式（去 `TextUtils.` 前缀，`this` 取值）。例如：
```dart
/// 反转字符串（按 UTF-16 code unit；emoji 修复见 Plan 3）。
String reverse() {
  final s = this;
  if (s == null) return '';
  return String.fromCharCodes(s.codeUnits.reversed);
}
```
（其余独有方法同理原样搬入，不改实现。）

- [ ] **Step 4: 删 text_utils**

Run:
```bash
git rm lib/text/text_utils.dart
rmdir lib/text
```

- [ ] **Step 5: 改写外部引用（TextUtils.x / text_utils import）**

对原 `text_utils` 的调用点，改为 string_ext 扩展调用：`textUtils.reverse(s)` → `s.reverse()`，并删除 `import ...text/text_utils.dart`。Run:
```bash
grep -rl -E "package:cutils/text/text_utils|textUtils\." lib example | while read f; do
  sed -i '' '/package:cutils\/text\/text_utils/d' "$f"
done
```
> 剩余 `textUtils.xxx(...)` 调用点需手工逐个改为扩展形式（`.xxx()`）。用 `grep -rn "textUtils\." lib example` 列出后逐个修改。

- [ ] **Step 6: 验证**

Run:
```bash
dart analyze
flutter test
```
Expected: 无未解析引用；测试全绿。

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: text/ 拆分——calculate→ui，谓词并入 string_ext，删 text_utils"
```

---

## Task 8: encrypt/ → crypto/（EncryptUtils → CryptoUtils）

**Files:**
- Move: `lib/encrypt/encrypt_utils.dart` → `lib/crypto/crypto_utils.dart`
- Modify: 类名 `EncryptUtils` → `CryptoUtils`；全局引用同步

- [ ] **Step 1: 移动并改名**

Run:
```bash
mkdir -p lib/crypto
git mv lib/encrypt/encrypt_utils.dart lib/crypto/crypto_utils.dart
rmdir lib/encrypt
sed -i '' 's/\bEncryptUtils\b/CryptoUtils/g' lib/crypto/crypto_utils.dart
```

- [ ] **Step 2: 改写外部引用**

Run:
```bash
grep -rl -E "package:cutils/encrypt/encrypt_utils|EncryptUtils" lib example | while read f; do
  sed -i '' \
    -e 's#package:cutils/encrypt/encrypt_utils#package:cutils/crypto/crypto_utils#' \
    -e 's/\bEncryptUtils\b/CryptoUtils/g' "$f"
done
```

- [ ] **Step 3: 验证**

Run:
```bash
dart analyze
flutter test
```
Expected: 无未解析引用；测试全绿。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: encrypt/→crypto/，EncryptUtils→CryptoUtils"
```

---

## Task 9: sp/ → storage/

**Files:**
- Move: `lib/sp/sp_util.dart` → `lib/storage/sp_util.dart`（文件名保留 `sp_util.dart`，类 `SpUtil` 不变；仅目录改名）

- [ ] **Step 1: 移动**

Run:
```bash
mkdir -p lib/storage
git mv lib/sp/sp_util.dart lib/storage/sp_util.dart
rmdir lib/sp
```

- [ ] **Step 2: 改写外部引用**

Run:
```bash
grep -rl "package:cutils/sp/sp_util" lib example | while read f; do
  sed -i '' 's#package:cutils/sp/sp_util#package:cutils/storage/sp_util#' "$f"
done
```

- [ ] **Step 3: 验证**

Run:
```bash
dart analyze
flutter test
```
Expected: 全绿。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: sp/→storage/"
```

---

## Task 10: 顶层 barrel `lib/cutils.dart`

**Files:**
- Modify: `lib/cutils.dart`（填入完整 barrel）

- [ ] **Step 1: 写 barrel**

写入 `lib/cutils.dart`：
```dart
/// cutils —— 通用 Flutter 工具库顶层 barrel。
///
/// 一行导入即可用全部核心工具：
/// ```dart
/// import 'package:cutils/cutils.dart';
/// ```
library;

// 类型扩展
export 'ext/ext_fun.dart';
// 数值与金额
export 'num/num_utils.dart';
export 'num/money_utils.dart';
export 'num/money_unit.dart';
// 日期时间
export 'datetime/date_utils.dart';
export 'datetime/data_formats.dart';
export 'datetime/timeline_util.dart';
export 'datetime/timer_util.dart';
// 正则 / JSON / 加解密
export 'regex/regex_utils.dart';
export 'regex/regex_constants.dart';
export 'json/json_utils.dart';
export 'crypto/crypto_utils.dart';
// 文件 / 存储 / 网络
export 'file/file_utils.dart';
export 'storage/sp_util.dart';
export 'net/net_util.dart';
export 'net/url_utils.dart';
// 系统
export 'system/device_info_util.dart';
export 'system/package_info_util.dart';
export 'system/keyboard_util.dart';
export 'system/system_utils.dart';
// UI / 事件 / 标识
export 'ui/calculate_utils.dart';
export 'ui/image_utils.dart';
export 'event/event_bus_util.dart';
export 'identifier/random_utils.dart';
export 'identifier/uuid_utils.dart';
// 日志
export 'log/log.dart';
// 日志收集子系统（已自带门面）
export 'log_collector/log_collector_export.dart';
```

- [ ] **Step 2: 写 barrel 解析测试**

创建 `test/cutils_barrel_test.dart`：
```dart
import 'package:cutils/cutils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel 导出关键公开符号', () {
    expect(DateTimeUtils, isNotNull);
    expect(NumUtils, isNotNull);
    expect(CryptoUtils, isNotNull);
    expect(logCollector, isNotNull);
  });
}
```

- [ ] **Step 3: 运行测试**

Run:
```bash
flutter test test/cutils_barrel_test.dart
```
Expected: PASS（验证所有 export 路径存在、无冲突）。

- [ ] **Step 4: 若有 export 冲突，按 spec D4 处理**

若 barrel 报 `name conflict`（多个导出同名），记录冲突符号，按 spec §11 D4：把易冲突的扩展从 barrel 拆出单独导出（不进 barrel），并在 README 列"随 barrel 注入的扩展清单"。本任务先解决冲突使测试通过。

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: 新增顶层 barrel lib/cutils.dart 统一导出"
```

---

## Task 11: 更新现有测试 import + 全量收尾

**Files:**
- Modify: `test/file/file_utils_test.dart`（import 路径随重组更新）

- [ ] **Step 1: 修 file_utils_test 的 import**

Run:
```bash
grep -rl "package:cutils/" test | while read f; do
  sed -i '' \
    -e 's#package:cutils/date/#package:cutils/datetime/#' \
    -e 's#package:cutils/sp/#package:cutils/storage/#' \
    -e 's#package:cutils/encrypt/#package:cutils/crypto/#' \
    -e 's#package:cutils/text/#package:cutils/ui/#' \
    "$f"
done
```
检查是否有 `plugin_platform_interface`/`cutils_platform_interface` 残留 import（应已在 Task 2 删测试时清掉）。

- [ ] **Step 2: dart format + dart fix**

Run:
```bash
dart format .
dart fix --apply
```
Expected: 格式化；`dart fix` 应用安全修复。

- [ ] **Step 3: 全量验证**

Run:
```bash
flutter pub get
dart analyze
flutter test
```
Expected: `dart analyze` 零告警；`flutter test` 全绿（含 file_utils_test、date_time_utils_test、cutils_barrel_test）。

- [ ] **Step 4: 更新 CLAUDE.md 模块地图（反映新结构）**

把 `CLAUDE.md` 的模块地图更新为新结构（datetime/crypto/storage/ui/event/identifier，删 scanner/serial/plugin 脚手架描述），并在 barrel 说明处加一句"顶层 barrel = `package:cutils/cutils.dart`"。

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: 收尾——更新测试 import、格式化、CLAUDE.md 模块地图"
```

- [ ] **Step 6: 合并回 master（可选，由用户决定）**

Run:
```bash
git checkout master
git merge --no-ff refactor/cutils-cleanup-restructure
```
Expected: 干净合并。

---

## 完成标准（Plan 1 Done Definition）

- [ ] `dart analyze` 零告警
- [ ] `flutter test` 全绿（含新增 date_time_utils_test、cutils_barrel_test）
- [ ] `lib/` 结构 = spec §3 目标结构（datetime/crypto/storage/ui/event/identifier 存在；date/time/encrypt/sp/text/utils/scanner/serial/plugin 脚手架 均已消失或迁移）
- [ ] `lib/cutils.dart` barrel 存在且可 `import 'package:cutils/cutils.dart';`
- [ ] pubspec 无 5 个死依赖、无 `flutter.plugin` 段、dartx 注释订正
- [ ] 单个 commit 历史清晰（每任务一提交）

## 不在 Plan 1（后续计划）

- Plan 2: 单例→静态类转换（spec §4）
- Plan 3: 高危 bug 修复 + 回归测试（spec §6.1）
- Plan 4: 中/低危修复 + dartdoc（spec §6.2/6.3、§8）
- Plan 5: example 演示页 + README + 迁移 cashier（spec §8/§9）
