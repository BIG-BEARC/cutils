# 方案评审记录：log_collector 条目级 suppressConsole（v1）

> **评审纪律声明**：本评审只评审、不修改被评审方案与任何代码；只输出建议与发现；未调用任何修改工具。评审者（plan-reviewer）为独立上下文 subagent，未见图与讨论过程；本文为评审返回值的**原样落盘**（主控机械转写，未过滤未修改）。

- 评审对象：`lib/log_collector/` 新增条目级「压制控制台输出」标志方案（详见本文 §一 方案成品）
- 评审者：crules-flutter:plan-reviewer（Read/Glob/Grep 只读）
- 评审日期：2026-10-12
- 结论：**技术通过**（无 🔴）；待消解项经需求方裁决全部闭合

## 方案成品（评审输入）

**特性**：`lib/log_collector/` 日志采集子系统新增条目级「压制控制台输出」标志。

**语义**：`suppressConsole: true` 的 LogEntry 照常进入采集管线（内存 + 文件存储，getLogs/export 可查），仅跳过「控制台类」输出器，用于 release 下低值/高频日志留档不刷屏。

**改动点**：
1. `lib/log_collector/log_entry.dart`：LogEntry 加 `final bool suppressConsole`（构造可选参数，默认 `false`）。不进 `toJson`/`fromJson`/`toString`——路由元数据非日志内容。
2. `lib/log_collector/log_output.dart`：`LogOutput` 抽象基类加实例 getter `bool get isConsole => false;`；`ConsoleLogOutput` override 为 `true`；`BatchLogOutput` override 转发 `delegate.isConsole`。理由：`is ConsoleLogOutput` 判断抓不到 `BatchLogOutput(delegate: ConsoleLogOutput())` 包装场景。
3. `lib/log_collector/log_collector.dart` 的 `_processLogQueue` 分发循环（约 175 行）：加判断 `if (entry.suppressConsole && output.isConsole) continue;`
4. `lib/log_collector/log_collector_helper.dart`：`log/debug/info/warning/error/fatal` 六个静态方法加可选参数 `bool suppressConsole = false` 透传。

**测试计划**：默认 false 全分发（回归）；suppressConsole=true 时 isConsole 输出器收不到、storage 照常入库且 getLogs 可查；helper 透传等价；BatchLogOutput 包装 console 场景；toJson 不含该字段。

**风险声明**：纯加法，默认行为不变；回退 = revert 单笔提交。

## 方案前置裁决（评审前，需求方选项卡拍板）

saas-cashier logging 借鉴四候选：① 业务分类 category 维度 → **不落地**（tag 已覆盖过滤/导出诉求，分文件改动面大）；② compute isolate 写盘 → **不做**（批量缓冲已摊薄，spawn 开销反超收益）；③ per-call 输出控制 → **仅做「只落盘」**（本方案）；④ kDebugMode 门控 → **撤销**（`kReleaseMode` 反向门控已存在，`lib/log/log.dart:17`）。

## 第一轮评审全文（plan-reviewer，2026-10-12）

### 一、真实性核对（评审要求 A）——方案声称的现状逐条回源

| # | 方案声称 | 核对结果 | 证据 |
|---|---------|---------|------|
| A1 | LogEntry 位于 `log_entry.dart`，构造为可选参数默认值模式 | 属实。构造在 79-90 行 | `lib/log_collector/log_entry.dart:79-90` |
| A2 | toJson / fromJson / toString 存在，字段可不进三者 | 属实。toString 94-115、toJson 118-130、fromJson 133-157，均手工逐字段组装，纯加法默认不进 | `log_entry.dart:94-157` |
| A3 | LogOutput 抽象基类，加带默认实现 getter 为纯加法 | 属实。基类仅 output/initialize/dispose（19-28 行）；既有测试桩 `_CountingOutput` 等子类在默认实现下零改动兼容——若做成 abstract getter 反而破坏子类，方案取舍正确 | `lib/log_collector/log_output.dart:19-28`；`test/log_collector/log_collector_wave_b_test.dart:24-49` |
| A4 | ConsoleLogOutput 存在；BatchLogOutput 包装 delegate，`is ConsoleLogOutput` 抓不到包装场景 | 属实。ConsoleLogOutput 31-70 行（developer.log 输出）；BatchLogOutput 146-229 行持有 delegate 缓冲转发，包装逃逸场景真实，isConsole 转发理由成立 | `log_output.dart:31-70, 146-229` |
| A5 | 分发循环「约 175 行」 | 精确命中。`_processLogQueue` 154-186 行，分发 for 循环恰在第 175 行 | `lib/log_collector/log_collector.dart:154-186` |
| A6 | 既有行为：minLevel / filterTags 过滤、maxQueueSize 队列丢弃 | 属实。minLevel 131-133、filterTags 136-139、队满丢新 142-144，全部在 collect 入队前 | `log_collector.dart:131-144` |
| A7 | helper 六静态方法 log/debug/info/warning/error/fatal | 属实（58/74/79/84/89/106 行），但有一处表述偏差，见发现 2 | `lib/log_collector/log_collector_helper.dart:58-120` |
| A8 | 内存 + 文件入库，getLogs/export 可查 | 属实。内存存对象引用（log_storage.dart:127-134）；文件走 jsonEncode(entry.toJson())（160 行）；getLogs = 内存原对象 + 文件 fromJson 重建（291-342）；export 用 toJson 写临时文件（397 行） | `lib/log_collector/log_storage.dart:127-134, 160, 291-342, 397` |
| A9 | dispose 排空路径 | 属实。dispose 复用 `_processLogQueue`（254 行），新判断自动覆盖排空 | `log_collector.dart:254` |

**结论：方案引用的文件、类结构、行号、既有行为全部属实，无虚构**。唯一表述偏差为发现 2。

### 二、发现清单（评审要求 B）

| # | 发现 | 严重度 | 原因 / 证据 | 建议（只建议，不改） |
|---|------|-------|------------|-------------------|
| 1 | 更优替代前置确认：若实际诉求是「release 全局不刷屏」，`quickInitialize(enableConsoleOutput: !kReleaseMode)` 零改动即可；条目级字段方案仅在「同进程内部分条目压制、部分不压制」场景下才必要 | 🟡 | `log_collector_helper.dart:27, 38-40`（开关已存在） | 进实施前向需求方确认条目级是真实需求；确认则本条消解。若确认条目级，三形态对比中「挂 LogEntry 字段」最优——挂 collect 参数会在进 BatchLogOutput 缓冲后丢失，挂输出器侧则每个输出器都需自行判断易漏 |
| 2 | helper 透传链表述偏差：debug/info/warning 不直接构造 LogEntry，而是中转 `log()`（75/80/85 行）；仅 log/error/fatal 直接构造（64/95/112 行）。方案对前三个实为两层透传 | 🟢 | `log_collector_helper.dart:74-86` vs `58-71, 89-120` | 实现时确保 log() 自身加参且 debug/info/warning 正确转发；「helper 透传等价」测试须覆盖中转路径，不能只测 log/error/fatal |
| 3 | isConsole 是声明制契约，需落 dartdoc：自定义输出器默认 false，若其向控制台写（debugPrint/print/developer.log）机制上拦不住，只能靠契约 | 🟢 | `log_output.dart:19-28` | 在 isConsole 的 dartdoc 写明「凡向控制台写入的输出器必须 override 为 true」 |
| 4 | suppressConsole 不拦 debugPrint 原始输出：DebugPrintInterceptor 收集前已调用 original debugPrint（66-68 行）；压制只作用于 LogOutput 分发面，使用方可能误以为控制台完全不可见 | 🟢 | `log_interceptor.dart:63-79` | 在 suppressConsole 的 dartdoc 写明语义边界：仅拦 collector 的 console 类输出器分发 |
| 5 | 序列化往返标志丢失 = 无持久语义。已核实当前无「getLogs 返回条目再分发」回流路径（collect 是唯一写入口），不影响现行为；但文件读回条目 suppressConsole 恒 false，未来若做日志回灌/重放会重新刷屏 | 🟢 | `log_storage.dart:313`；`log_collector.dart:124`（collect 唯一写入口） | dartdoc 标注「仅进程内分发路由有效，不持久化」；不进 toJson 的取舍本身正确，维持 |
| 6 | 测试计划遗漏三点：a) dispose 排空路径一致性（suppressConsole 条目在排空时同样跳过 console）；b) 未显式列「非 console 输出器照常收到」（防误伤全部分发）；c) Batch 嵌套（batch(batch(console))）递归转发一层防回归 | 🟢 | `log_collector.dart:254`；既有测试组织 `test/log_collector/` 5 文件、wave 分组风格、`_CountingOutput` 桩（wave_b:24-49）可复用 | 测试计划补 a/b/c；落位按既有 wave 组织，沿用既有桩 |
| 7 | error/fatal 带 suppressConsole 的 API 语义存疑：错误/致命恰是 release 下最需要控制台可见的级别，参数对称但可能诱导误用 | 🟢 | `log_collector_helper.dart:89-120` | 可选裁决：error/fatal 不加（YAGNI）或保留加慎用提示；默认 false 无害，归需求方 |

### 三、交互面核查（无发现，记录核查过程）

- minLevel / filterTags / maxQueueSize 全在 collect 入队前（131-144 行），新判断在分发时（175 行循环内），无交叠。
- 分发循环为快照遍历，`continue` 不影响其余输出器。
- 压制条目在 collector 层即被 continue、不进 batch 缓冲——恰好正确：若进缓冲，flush 时 delegate 直收 entry 将无二次判断点。拦截层级选择正确。
- collector 自身错误日志（debugPrint，170/179 行）不走 LogEntry，不受影响。
- `log_collector_export.dart` 整文件 export、无 show 限制，纯加法无需改导出。
- LogEntry 无 operator==/hashCode/copyWith，新字段无连带影响；默认 false 下既有测试零破坏。

### 整体结论

**技术通过**（无 🔴 须消解项）。方案现状引用全部属实、行号精确，核心形态取舍（字段挂 LogEntry + collector 集中判断 + isConsole 声明制 getter）在候选形态中成立且有实证支撑。1 条 🟡（发现 1）+ 6 条 🟢（多为 dartdoc 契约落字与测试计划补点），不阻断实施。

## 产出者逐条回应

- **发现 1（🟡）**：评审者缺裁决上下文（隔离所致）。条目级场景在需求方前置裁决时已明确选定——选项原文即「release 下低值/高频日志想留档但不刷控制台」（部分条目压制、error 等照常刷屏），非全局诉求。按流程仍列确认项，确认即消解。
- **发现 2**：属实（方案表述不精确），采纳修正：`log()` 为透传中枢加参，debug/info/warning 转发；测试覆盖中转路径。
- **发现 3/4/5**：采纳，三处 dartdoc 落字（契约声明 / 语义边界 / 不持久化标注）。
- **发现 6**：采纳，测试计划 +3（排空一致性 / 非 console 照常收到 / 双层 batch 嵌套）。
- **发现 7**：开放点，归需求方裁决。

## 需求方裁决记录（2026-10-12，选项卡）

| 裁决项 | 结果 |
|---|---|
| 发现 1（🟡）条目级确认 | **确认条目级**——部分条目压制、部分不压制为真实场景，发现 1 消解 |
| 发现 7（🟢）error/fatal 参数 | **保留加**——六方法对称，默认 false 无行为差异 |

## 闭环结论

评审结论在手 + 待消解项全部闭合（发现 1 确认消解；发现 7 裁决保留；发现 2-6 产出者采纳）+ 需求方裁决即通过 → **进实施**。实施按 TDD：测试先行（红）→ 四文件实现（绿）→ `dart analyze` 零 warning + `dart format` 归零。
