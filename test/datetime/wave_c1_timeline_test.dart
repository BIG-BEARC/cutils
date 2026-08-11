import 'package:cutils/datetime/abs_time_info.dart';
import 'package:cutils/datetime/day_format.dart';
import 'package:cutils/datetime/timeline_util.dart';
import 'package:flutter_test/flutter_test.dart';

// Wave C1 — timeline_util 中危修复。
// 全确定性：固定毫秒 + 可选 isUtc；不依赖宿主墙钟（locTimeMs 显式注入）。

/// 后缀冲突（ago == after）的假 locale，用于验证方向判定不靠字符串比较。
class _CollidingInfo implements TimelineInfo {
  @override
  String suffixAgo() => '·'; // 与 suffixAfter 相同 —— 字符串相等会导致漏判。

  @override
  String suffixAfter() => '·';

  @override
  int maxJustNowSecond() => 30;

  @override
  String lessThanOneMinute() => 'just now';

  @override
  String customYesterday() => '';

  @override
  bool keepOneDay() => false;

  @override
  bool keepTwoDays() => false;

  @override
  String oneMinute(int minutes) => 'a minute';

  @override
  String minutes(int minutes) => '$minutes minutes';

  @override
  String anHour(int hours) => 'an hour';

  @override
  String hours(int hours) => '$hours hours';

  @override
  String oneDay(int days) => 'a day';

  @override
  String weeks(int week) => '';

  @override
  String days(int days) => '$days days';
}

void main() {
  // C1.7 — setLocaleInfo 不再使用 deprecated ArgumentError.checkNotNull。
  //        （由 dart analyze 验证无 deprecated_member_use；此用例保证调用不抛。）
  group('C1.7 setLocaleInfo no deprecated checkNotNull', () {
    test('注册一个自定义 locale 不抛异常', () {
      setLocaleInfo('_test_col', _CollidingInfo());
      // 能取回（间接经 format 验证）。
      final nowMs = DateTime.utc(2026, 1, 15, 12, 0).millisecondsSinceEpoch;
      final pastMs =
          DateTime.utc(2026, 1, 15, 11, 59, 50).millisecondsSinceEpoch;
      expect(
        TimelineUtil.format(pastMs, locTimeMs: nowMs, locale: '_test_col'),
        isA<String>(),
      );
    });
  });

  // C1.8 — 方向（ago/after）由 bool 决定，不靠 suffix 字符串相等。
  group('C1.8 direction by bool not string', () {
    test('后缀冲突时，过去近况仍走 just now（不被 suffixAgo==suffixAfter 误判）', () {
      final nowMs = DateTime.utc(2026, 1, 15, 12, 0).millisecondsSinceEpoch;
      // 过去 10 秒：seconds < 90 && < maxJustNowSecond(30) → 'just now'。
      final pastMs =
          DateTime.utc(2026, 1, 15, 11, 59, 50).millisecondsSinceEpoch;
      final res =
          TimelineUtil.format(pastMs, locTimeMs: nowMs, locale: '_test_col');
      // 旧实现：suffix('·') != suffixAfter('·') 为 false → 跳过 just now，
      // 返回 'a minute·'。修复后：!isFuture → true → 'just now'。
      expect(res, 'just now');
    });
  });

  // C1.9 — isUtc 线程：UTC 毫秒近午夜，按 UTC 日历格式化（不被当 local 误判）。
  group('C1.9 isUtc threading', () {
    test('UTC 近午夜（local 已跨日）按 UTC 日期输出', () {
      // UTC 2026-01-10 23:30；本机 UTC+8 的 local 已是 01-11 07:30。
      final ms = DateTime.utc(2026, 1, 10, 23, 30).millisecondsSinceEpoch;
      // 一个"几天前"的当前时刻，使 format 落入 _formatDays(common) → MM-dd。
      final nowMs = DateTime.utc(2026, 1, 15, 12, 0).millisecondsSinceEpoch;
      final res =
          TimelineUtil.format(ms, locTimeMs: nowMs, locale: 'en', isUtc: true);
      // common → MM-dd，UTC → '01-10'；未线程时（local）→ '01-11'（本机）。
      expect(res, '01-10');
    });

    test('formatByDateTime 推导 isUtc（UTC DateTime → UTC 日历）', () {
      final dt = DateTime.utc(2026, 1, 10, 23, 30);
      final loc = DateTime.utc(2026, 1, 15, 12, 0);
      final res = TimelineUtil.formatByDateTime(dt,
          locDateTime: loc, locale: 'en', dayFormat: DayFormat.common);
      expect(res, '01-10');
    });
  });

  // C1.10 — formatA 未来日期返回 formatToday（文档化行为）。
  group('C1.10 formatA future-date behavior', () {
    test('未来毫秒返回 formatToday (默认 HH:mm) 而非 weekday/yyyy', () {
      final nowMs = DateTime.utc(2026, 1, 15, 12, 0).millisecondsSinceEpoch;
      // 未来 1 天。
      final futureMs = DateTime.utc(2026, 1, 16, 9, 30).millisecondsSinceEpoch;
      final res = TimelineUtil.formatA(futureMs, locMs: nowMs, isUtc: true);
      expect(res, '09:30');
    });

    test('formatA 过去非今日/昨日/本周 → 完整 yyyy-MM-dd', () {
      final nowMs = DateTime.utc(2026, 1, 15, 12, 0).millisecondsSinceEpoch;
      // 一年前。
      final pastMs = DateTime.utc(2025, 1, 10, 9, 30).millisecondsSinceEpoch;
      final res = TimelineUtil.formatA(pastMs, locMs: nowMs, isUtc: true);
      expect(res, '2025-01-10');
    });
  });
}
