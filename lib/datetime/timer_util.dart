import 'dart:async';

import 'package:flutter/foundation.dart';

///timer callback.(millisUntilFinished 毫秒).
typedef OnTimerTickCallback = void Function(int millisUntilFinished);

/// TimerUtil —— 通用定时器 / 倒计时工具。
///
/// 提供 [startTimer]（周期定时）与 [startCountDown]（倒计时）两种模式；
/// 倒计时基于启动时固定的 `endTime` 墙钟，避免 [Timer.periodic] 漂移。
/// 不再使用时请调用 [cancel] / [dispose] 释放底层 [Timer]。
class TimerUtil {
  TimerUtil(
      {this.mInterval = Duration.millisecondsPerSecond, this.mTotalTime = 0});

  /// Timer.
  Timer? _mTimer;

  /// Tail one-shot Timer used for the final sub-interval of a countdown.
  /// Tracked so [cancel] can revoke it; otherwise a stale callback could
  /// fire after cancel/restart and corrupt a new run.
  Timer? _mTailTimer;

  /// Is Timer active.
  /// Timer是否启动.
  bool _isActive = false;

  /// 可注入的时钟；默认 [DateTime.now]。测试用 [FakeAsync] 时覆盖它，
  /// 使 [startCountDown] 的墙钟计算可由测试驱动（本测试环境下 FakeAsync
  /// 接管 [Timer] 但不接管 `DateTime.now()`）。
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// Timer interval (unit millisecond，def: 1000 millisecond).
  /// Timer间隔 单位毫秒，默认1000毫秒(1秒).
  int mInterval;

  /// countdown totalTime.
  /// 倒计时总时间
  int mTotalTime; //单位毫秒

  OnTimerTickCallback? _onTimerTickCallback;

  /// set Timer interval. (unit millisecond).
  /// 设置Timer间隔.
  void setInterval(int interval) {
    if (interval <= 0) interval = Duration.millisecondsPerSecond;
    mInterval = interval;
  }

  /// set countdown totalTime. (unit millisecond).
  /// 设置倒计时总时间.
  void setTotalTime(int totalTime) {
    if (totalTime <= 0) return;
    mTotalTime = totalTime;
  }

  /// start Timer.
  /// 启动定时Timer.
  void startTimer() {
    if (_isActive || mInterval <= 0) return;
    _isActive = true;
    final Duration duration = Duration(milliseconds: mInterval);
    _doCallback(0);
    _mTimer = Timer.periodic(duration, (Timer timer) {
      _doCallback(timer.tick);
    });
  }

  /// start countdown Timer.
  /// 启动倒计时Timer.
  ///
  /// Remaining time is derived from a wall-clock end time captured once at
  /// start (`endTime = now + mTotalTime`), so the countdown stays in sync
  /// with real elapsed time even if [Timer.periodic] drifts under load. The
  /// configured [mTotalTime] is not consumed as running state.
  void startCountDown() {
    if (_isActive || mInterval <= 0 || mTotalTime <= 0) return;
    _isActive = true;
    final DateTime endTime = now().add(Duration(milliseconds: mTotalTime));
    final Duration duration = Duration(milliseconds: mInterval);
    _doCallback(mTotalTime);
    _mTimer = Timer.periodic(duration, (Timer timer) {
      final int remaining = endTime.difference(now()).inMilliseconds;
      if (remaining >= mInterval) {
        _doCallback(remaining);
      } else if (remaining <= 0) {
        _doCallback(0);
        cancel();
      } else {
        // Final sub-interval: stop the periodic timer and schedule one
        // trailing tick at the precise end time.
        timer.cancel();
        _mTailTimer = Timer(Duration(milliseconds: remaining), () {
          if (!_isActive) return;
          _doCallback(0);
          cancel();
        });
      }
    });
  }

  void _doCallback(int time) {
    final cb = _onTimerTickCallback;
    if (cb != null) {
      cb(time);
    }
  }

  /// Update countdown totalTime as a PURE setter.
  ///
  /// 只更新 [mTotalTime]，**不**取消或重启正在运行的倒计时。若正在倒计时，
  /// 其 `endTime`（启动时已固定）不受影响；如需让新总数生效，请用 [restart]。
  ///
  /// BREAKING: 旧实现会 `cancel() → set → startCountDown()` 隐式重启。
  void updateTotalTime(int totalTime) {
    if (totalTime <= 0) return;
    mTotalTime = totalTime;
  }

  /// Restart the countdown with a new totalTime.
  ///
  /// 取消当前计时（如有）并以 [totalTime] 为新总数重新启动倒计时。等价于旧的
  /// `updateTotalTime` 组合行为（cancel + set + start）。
  void restart(int totalTime) {
    cancel();
    if (totalTime <= 0) return;
    mTotalTime = totalTime;
    startCountDown();
  }

  /// timer is Active.
  /// Timer是否启动.
  bool isActive() {
    return _isActive;
  }

  /// Cancels the timer.
  /// 取消计时器.
  void cancel() {
    _mTimer?.cancel();
    _mTimer = null;
    _mTailTimer?.cancel();
    _mTailTimer = null;
    _isActive = false;
  }

  /// Releases resources by cancelling the underlying [Timer]s.
  ///
  /// 生命周期约定：持有 [TimerUtil] 的对象在销毁时应调用 [dispose]（或
  /// [cancel]）以释放底层 `dart:async` [Timer]，避免回调泄漏。本方法等价于
  /// [cancel]，提供与有状态组件（`State.dispose`）一致的命名。
  void dispose() => cancel();

  /// set timer callback.
  void setOnTimerTickCallback(OnTimerTickCallback callback) {
    _onTimerTickCallback = callback;
  }
}
