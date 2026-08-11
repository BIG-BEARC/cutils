# log_collector 崩溃 flush 设计

- **日期**: 2026-08-11
- **状态**: 待评审
- **范围**: `log_collector` 子系统 —— 仅"保住 Dart 可感知崩溃前的日志"
- **不在范围**: PII 脱敏、`outputBatch` 批量接口、`NetworkLogOutput` 实现 —— 均因 YAGNI 暂不做（待日志是否流出设备明确后再议）

---

## 1. 目标

让 **Dart 可感知的崩溃/错误**不因 IOSink 缓冲 + 定时 flush（默认 5s）而丢日志：`error/fatal` 级日志即时落盘；并提供公开 `flush()` 供宿主 app 在生命周期/风险点强制排空。

## 2. 现状

`LogStorage` 文件写入走持久化 `IOSink`（append），由 `Timer.periodic(flushInterval)` 周期性 flush，**不在每条 store 后 flush**。所有级别一视同仁。`error/fatal` 与 `info` 一样最多滞留 `flushInterval`（默认 5s）才落盘——硬崩溃/进程被杀时这部分丢失。而崩溃前最后那几秒恰恰是排障最需要的。

## 3. 设计

### 3.1 error/fatal 即时 flush（LogStorage）
`LogStorage._storeInFile` 写入一行后，**若该条目级别 ≥ error**（`entry.level.index >= LogLevel.error.index`），立即 `await _fileSink?.flush()` 再返回。

- 复用既有 `IOSink` 通道（不另开 fd、不双通道）。
- 仅 `error/fatal` 触发——这两类低频、关键；`info/debug/verbose` 仍走定时 flush，稳态 IO 不增。
- flush 失败已被 `_storeInFile` 的 try/catch 覆盖（记 debugPrint，不影响队列排空）。

### 3.2 公开 `flush()` API（LogCollector + LogStorage）
- `LogStorage.flush()`：`await _fileSink?.flush()`（把现有 `flushForTesting` 提升为公开方法，或新增公开 `flush()` 别名）。
- `LogCollector.flush()`：`await _processLogQueue()`（先排空队列，让待处理条目都过了 store）→ `await _storage?.flush()`（再强制落盘）。
- 仅供宿主 app 在已知风险点调用，典型：`AppLifecycleState.paused/detached`（手机后台杀进程是真实丢日志场景）、上传/导出前、长耗时操作前。

### 3.3 不耦合 Flutter 生命周期
collector **不**自己注册 `WidgetsBindingObserver`——生命周期感知属宿主 app。collector 只暴露 `flush()`，由宿主在生命周期回调里调用。保持 collector 与 Flutter framework 解耦（与现状一致）。

## 4. 诚实边界

- **native OOM / SIGKILL 无法在 Dart 拦截**：任何 Dart 钩子都来不及 flush。这部分靠缩短 `LogCollectorConfig.flushInterval`（已暴露）减小丢失窗口；error/fatal 已即时 flush，所以丢失的至多是崩溃前最后 `flushInterval` 内的**非 error** 日志。
- **Dart 可感知的崩溃已覆盖**：`ExceptionInterceptor` 捕获的未处理异常（`FlutterError.onError` / `PlatformDispatcher.onError`）走 `collect` → 命中 error/fatal → 即时 flush。

## 5. 测试

- **error 即时落盘**：`collect` 一条 error 级 → `await` 处理 → 在**不推进 `flushInterval`** 的情况下读文件，断言该行已存在。
- **info 不即时**：`collect` 一条 info 级 → `await` 处理 → 推进 `flushInterval` 前断言文件为空（或不含该行）→ 推进后断言存在。验证级别定向。
- **`logCollector.flush()`**：入队若干 → `await flush()` → 断言队列空（`pendingLogCount == 0`）+ 文件含全部行（未推进定时器）。
- 全部用 `FakeAsync` 驱动 `flushInterval` 定时器；无真实延迟、确定性。

## 6. 兼容性

纯增量（新增 `flush()` 公开方法 + error/fatal flush 行为），**无破坏性 API 变更**。`error/fatal` 即时 flush 是行为改善（原本最终也会落盘，只是更晚），不改变对外契约。补 dartdoc + CHANGELOG（下一次版本）。
