import 'package:cutils/datetime/timer_util.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

// Wave F — high-severity timer fixes (F3 drift, F4 stale tail).
//
// FakeAsync 驱动 Timer.periodic；本环境下它不接管 DateTime.now()，故
// TimerUtil.now 注入一个可变时钟，测试用 step() 「先推进时钟再 elapse」，
// 使每次 periodic tick 看到正确的 now()。无真实墙钟等待。
void main() {
  tearDown(() => TimerUtil.now = DateTime.now);

  group('F3 countdown tracks wall-clock', () {
    test('remaining tracks elapsed wall-clock, no drift', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        // 先推进时钟再 elapse：periodic tick 在 elapse 边界触发时读到的
        // now() 即为推进后的值，与 fake 时间同步。
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        final timer = TimerUtil(mInterval: 1000, mTotalTime: 10000);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        timer.startCountDown(); // 立即 tick: 10000
        expect(ticks.last, 10000);

        step(const Duration(seconds: 1)); // 1s: 剩 9000
        expect(ticks.last, 9000);
        step(const Duration(seconds: 1)); // 2s: 剩 8000
        expect(ticks.last, 8000);
        step(const Duration(seconds: 1)); // 3s: 剩 7000
        expect(ticks.last, 7000);

        // 墙钟派生剩余时间，mTotalTime 不被当作运行态消耗。
        expect(timer.mTotalTime, 10000);
        expect(timer.isActive(), isTrue);
      });
    });

    test('full countdown reaches zero at the wall-clock-correct instant', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        final timer = TimerUtil(mInterval: 1000, mTotalTime: 3000);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        timer.startCountDown();

        step(const Duration(seconds: 1)); // 剩 2000
        step(const Duration(seconds: 1)); // 剩 1000
        step(const Duration(seconds: 1)); // 剩 0 → 回调 0 + cancel

        expect(ticks, [3000, 2000, 1000, 0]);
        expect(timer.isActive(), isFalse);
      });
    });
  });

  group('F4 cancel cancels pending tail', () {
    test('no stale tail callback fires after cancel()', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        // total=3500, interval=1000 → 3 整 tick 后剩 500ms 进入 tail 分支。
        final timer = TimerUtil(mInterval: 1000, mTotalTime: 3500);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        timer.startCountDown();

        step(const Duration(seconds: 1)); // 2500
        step(const Duration(seconds: 1)); // 1500
        step(const Duration(seconds: 1)); // 剩 500 → 进入 tail，排程 500ms 尾 tick
        expect(ticks, [3500, 2500, 1500]);

        timer.cancel(); // 取消 tail Timer

        // 推进过 tail 本应触发的 3.5s 点。
        step(const Duration(milliseconds: 500));

        // 被取消的尾 tick 没有触发。
        expect(ticks, [3500, 2500, 1500]);
        expect(timer.isActive(), isFalse);
      });
    });

    test('a stale tail from a previous run does not corrupt a new run', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        final timer = TimerUtil(mInterval: 1000, mTotalTime: 3500);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);

        // Run 1: 进入 tail 分支后 cancel。
        timer.startCountDown();
        step(const Duration(seconds: 1));
        step(const Duration(seconds: 1));
        step(const Duration(seconds: 1)); // 进入 tail
        timer.cancel();
        expect(ticks, [3500, 2500, 1500]);

        // Run 2: 全新倒计时；只应记录它自己的回调。
        final runTwoTicks = <int>[];
        timer.setOnTimerTickCallback(runTwoTicks.add);
        timer.mTotalTime = 2000;
        timer.startCountDown(); // 立即 tick: 2000
        step(const Duration(seconds: 1)); // 剩 1000
        step(const Duration(seconds: 1)); // 剩 0 → cancel

        // Run 1 的 stale tail（本会在 3.5s 触发）从未触碰 ticks。
        expect(ticks, [3500, 2500, 1500]);
        // Run 2 干净完成。
        expect(runTwoTicks, [2000, 1000, 0]);
      });
    });
  });
}
