# platform-pitfalls.md · 平台坑库

> 用途：引依赖（T1）/ 写平台代码（T2）/ 升级（T3）前查本库；**支持矩阵是所有平台判据的基线**。
> **两处坑库的分工**：本文件收**本项目实测**踩到的坑；Flutter / 框架级通用坑见 flutter-rules skill「平台坑库」（`references/platform-pitfalls.md`，随 plugin 分发维护）。本项目坑若跨项目复现、具备通用价值，经 `/crules-flutter:distill` 提名上移进 skill 侧。
> 坑卡模板为**全字段权威**：症状 / 规避必填，根因查明后填；**归属**为层级归属（独立于根因查明可填），是 T0–T5 检索键。
> 状态规则：已修复**不删卡**（标「已修复于 vX」——老版本环境仍在）。
> 实证口径：坑卡引用的私有仓 commit 哈希属生产实证但外界不可复现——对外视作信任声明；跨项目通用坑上移 skill 侧时优先换公库 issue / 官方文档链接。

## 支持矩阵【装完必填·第三处】

> init 三段式生成初稿：①机械读（平台目录 + minSdk + Podfile）→ ②人核对 → ③人补实测上限。
> 矩阵与 build.gradle / Podfile 打架 = 配置漂移信号，须报告修正。

| 平台 | 支持区间 / 判据 | 实测上限 | 备注 |
|---|---|---|---|
| Android | 【待填·init 三段式生成】 | 【待填·人补】 | minSdk 源：android/app/build.gradle |
| iOS | 【待填·init 三段式生成】 | 【待填·人补】 | 下限源：ios/Podfile platform :ios |
| Windows | 【待填·init 三段式生成】 | 【待填·人补】 | |
| macOS / Linux / Web | 【待填·按需增删本行】 | | 无该平台目录即删行 |

**消费端兜底**：坑检查读到 `【待填` = 判据缺失，当场顶回「请先填矩阵」，不静默盲查。

## 坑卡（新卡按以下结构追加，一卡一节）

```markdown
## [<暴露平台>] <一句话症状>
- 归属：OS 平台 / Flutter SDK / 三方依赖 / 未定性 ← 层级归属，独立于根因查明可填（提闸必填，T0–T5 检索键；「未定性」不参与 T1/T3 精确检索、T2 可见）
- 触发场景：<何时踩到> ｜ 症状：<现象> ｜ 根因：<查明后填> ｜ 规避：<换库/条件引入/钉版本等>
- 区间：<平台 × 依赖或 SDK × 版本，交叉积>
- 状态：未修复｜已修复于 vX（不删卡，老环境仍在） ｜ 最后核验：<日期>
- 出处：复盘链接 + 官方 issue
```

## [全平台] Dart `num.round()` 不是银行家舍入——手写 roundHalfUp 反而引入浮点 bug
- 归属：Dart SDK（语言语义）
- 触发场景：吸收/移植其它语言（Java 注释习惯）的工具代码，或凭印象写「半舍入」 ｜ 症状：自实现 `(v + 0.5).truncate()` 式 roundHalfUp 在特定输入上差 1；注释宣称「Dart .round() 是银行家舍入」与实际行为不符 ｜ 根因：Dart `round()` 语义是 **half away from zero**（2.5→3、-2.5→-3，等价 Java `RoundingMode.HALF_UP`），并非银行家舍入（HALF_EVEN）；而 `(v + 0.5).truncate()` 有经典浮点边界 bug——`0.49999999999999994 + 0.5 == 1.0`（double 表示误差），截断得 1，正确应得 0 ｜ 规避：半数向上舍入直接用内置 `round()`；金额类高精度场景走 `Decimal`（本项目 `MoneyUtils`）不进 double
- 区间：Dart SDK 全版本（语言规范行为） × 本仓实测（2026-10-12 `dart run` 临时脚本）
- 状态：未修复（语言行为非缺陷，长期有效） ｜ 最后核验：2026-10-12
- 出处：saas_pos_smart_edition `shared/utils/round_half_up` 类实现审查（吸收评估中实测证伪，未吸收）；行为依据 Dart 语言规范 `double.round()`

## [iOS] immersiveSticky 隐藏状态栏后 `MediaQuery.padding.top` 不同步归零——Scaffold 内容整体下移
- 归属：Flutter SDK（engine 时序）
- 触发场景：iOS 上用 `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` 隐藏 status bar 后布局 ｜ 症状：status bar 已隐藏但 `MediaQuery.padding.top` 仍是旧值（不同步归零的时序 bug），Scaffold 据此把内容推下，页面整体下移 ｜ 根因：engine 侧 padding 更新与 UI 模式切换异步，读取到的是切换前快照 ｜ 规避：不依赖 status bar 隐藏时序——在 `MaterialApp.builder` 中对该页 `MediaQuery.removePadding(context: removeTop: true)` 强制 padding=0；**不要**依赖 Info.plist 的 `UIStatusBarHidden`（会被 Flutter engine 覆盖，不可靠），iOS 隐藏 status bar 仍走 immersiveSticky
- 区间：iOS × Flutter engine（immersiveSticky 模式） ｜ Android 无此坑
- 状态：未修复（engine 行为，规避法长期有效） ｜ 最后核验：2026-10-12
- 出处：saas_pos_smart_edition `core/utils/fullscreen_util.dart` 头注（生产实证，原作者 甄灿兵）；能力吸收评估时采集
