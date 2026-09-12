import 'package:cutils/datetime/timer_util.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

// Wave C1 — timer_util 中危修复。
// 全部 FakeAsync + 注入 TimerUtil.now，无真实墙钟等待。
void main() {
  tearDown(() => TimerUtil.now = DateTime.now);

  // C1.11 — updateTotalTime 变为纯 setter（不再隐式重启）；
  //         旧 cancel+set+start 的合并行为改由 restart(int) 提供。
  group('C1.11 updateTotalTime pure setter / restart', () {
    test('updateTotalTime 只设总数，不重启（无即时 tick 爆发）', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        final timer = TimerUtil(mInterval: 1000, mTotalTime: 10000);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        timer.startCountDown(); // 立即 tick 10000
        step(const Duration(seconds: 1)); // tick 9000

        final ticksBefore = ticks.length;
        // 纯 setter：不应触发即时 tick，也不取消正在运行的倒计时。
        timer.updateTotalTime(5000);
        expect(timer.mTotalTime, 5000);
        expect(ticks.length, ticksBefore); // 没有新 tick
        expect(timer.isActive(), isTrue); // 原倒计时仍在跑

        // 原倒计时（基于其 endTime，total=10000）继续：再 1s → 剩 8000。
        step(const Duration(seconds: 1));
        expect(ticks.last, 8000);
      });
    });

    test('restart(int) 取消并按新总数重启（立即 tick 新总值）', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        final timer = TimerUtil(mInterval: 1000, mTotalTime: 10000);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        timer.startCountDown(); // tick 10000
        step(const Duration(seconds: 1)); // tick 9000

        timer.restart(5000); // 立即 tick 新总值 5000
        expect(timer.mTotalTime, 5000);
        expect(ticks.last, 5000);
        expect(timer.isActive(), isTrue);

        // 新倒计时按 5000 推进。
        step(const Duration(seconds: 1)); // 剩 4000
        expect(ticks.last, 4000);
      });
    });

    test('restart 在未启动状态下启动倒计时', () {
      fakeAsync((async) {
        final clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        final timer = TimerUtil(mInterval: 1000, mTotalTime: 0);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        // 未启动（mTotalTime=0）→ restart 设新值并启动。
        timer.restart(3000);
        expect(timer.mTotalTime, 3000);
        expect(timer.isActive(), isTrue);
        expect(ticks.last, 3000);
      });
    });
  });

  // C1.12 — dispose() 作为 cancel() 的别名 + 生命周期文档。
  group('C1.12 dispose', () {
    test('dispose 取消计时器（isActive 变 false）', () {
      fakeAsync((async) {
        final clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        final timer = TimerUtil(mInterval: 1000, mTotalTime: 10000);
        timer.startCountDown();
        expect(timer.isActive(), isTrue);

        timer.dispose();
        expect(timer.isActive(), isFalse);
      });
    });

    test('dispose 后推进时间不再产生 tick', () {
      fakeAsync((async) {
        var clk = DateTime(2026, 1, 1);
        TimerUtil.now = () => clk;
        void step(Duration d) {
          clk = clk.add(d);
          async.elapse(d);
        }

        final timer = TimerUtil(mInterval: 1000, mTotalTime: 10000);
        final ticks = <int>[];
        timer.setOnTimerTickCallback(ticks.add);
        timer.startCountDown(); // tick 10000
        final beforeDispose = ticks.length;

        timer.dispose();
        step(const Duration(seconds: 5));

        expect(ticks.length, beforeDispose); // dispose 后没有更多 tick
        expect(timer.isActive(), isFalse);
      });
    });
  });
}
