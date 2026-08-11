import 'package:cutils/datetime/date_utils.dart';
import 'package:cutils/datetime/data_formats.dart';
import 'package:flutter_test/flutter_test.dart';

// Wave C1 — date_utils 中危修复。
// 全部确定性测试：使用固定 DateTime（多为 UTC）断言，不依赖宿主时区墙钟。
void main() {
  // C1.1 — getYesterday 必须按"日历日"回退（DateTime 构造器跨 DST/月/年归一化），
  //        而不是减固定 24*60*60*1000 毫秒。
  group('C1.1 getYesterday calendar arithmetic', () {
    test('UTC 输入 → 返回前一个日历日（UTC 保持，跨年月）', () {
      // 注入固定 UTC 时刻；旧实现用 fromMillisecondsSinceEpoch(ms)（无 isUtc）
      // 总是返回 local，且按 24h 减——UTC 输入会被判为 local（isUtc 不匹配）。
      final now = DateTime.utc(2026, 1, 10, 12, 0);
      final yesterday = DateTimeUtils.getYesterday(now: now);
      expect(yesterday, DateTime.utc(2026, 1, 9, 12, 0));
      expect(yesterday.isUtc, isTrue);
      expect(yesterday.day, 9);
    });

    test('月初回退到上月最后一天', () {
      final now = DateTime.utc(2026, 3, 1, 6, 0);
      final yesterday = DateTimeUtils.getYesterday(now: now);
      expect(yesterday, DateTime.utc(2026, 2, 28, 6, 0));
    });

    test('年初回退到上年 12-31', () {
      final now = DateTime.utc(2026, 1, 1, 0, 0);
      final yesterday = DateTimeUtils.getYesterday(now: now);
      expect(yesterday, DateTime.utc(2025, 12, 31, 0, 0));
    });

    test('无参调用仍以 DateTime.now() 为基准返回昨天', () {
      final now = DateTime.now();
      final yesterday = DateTimeUtils.getYesterday();
      // 同一时刻构造的"昨天"日历日应比今天少一天（跨月/年归一化）。
      final expected = DateTime(
        now.year,
        now.month,
        now.day - 1,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond,
      );
      expect(yesterday.year, expected.year);
      expect(yesterday.month, expected.month);
      expect(yesterday.day, expected.day);
    });
  });

  // C1.2 — isToday/isWeek 不应把 epoch 0（1970-01-01）当作"无值"。
  //        只有 null 是缺失哨兵。
  group('C1.2 zero-guard removal', () {
    test('isToday(0) 不再被 == 0 守卫自动判 false', () {
      // epoch 0 = 1970-01-01 UTC。isUtc:true + locMs:0 → 两边都是 epoch 同日 → true。
      // 旧实现因 milliseconds == 0 直接返回 false。
      expect(DateTimeUtils.isToday(0, isUtc: true, locMs: 0), isTrue);
    });

    test('isToday(null) 仍返回 false（null 是唯一缺失哨兵）', () {
      expect(DateTimeUtils.isToday(null), isFalse);
    });

    test('isWeek(0) 不再被 ms <= 0 守卫自动判 false', () {
      // epoch 与自身比较，同一周内 → true。旧实现因 ms <= 0 直接返回 false。
      expect(DateTimeUtils.isWeek(0, isUtc: true, locMs: 0), isTrue);
    });

    test('isWeek(null) 仍返回 false', () {
      expect(DateTimeUtils.isWeek(null), isFalse);
    });
  });

  // C1.3 — 跨时区归一化。
  group('C1.3 cross-zone normalization', () {
    test('isYesterday 同区(UTC) 跨年边界正确', () {
      final dt = DateTime.utc(2025, 12, 31, 12, 0);
      final loc = DateTime.utc(2026, 1, 1, 12, 0);
      expect(DateTimeUtils.isYesterday(dt, loc), isTrue);
    });

    test('getWeekNumber UTC 输入保持 UTC（递归不混入 local）', () {
      // 2021-01-01 属于 2020 年第 53 周（ISO）。UTC 输入 → 结果与 zone 无关。
      // 该用例触发 getWeekNumber 的 else 分支（递归到上年 12-31）。
      final wn = DateTimeUtils.getWeekNumber(DateTime.utc(2021, 1, 1));
      expect(wn, 53);
    });

    test('getDayOfYear 不再依赖 MONTH_DAY（改用 DateTime 归一化，闰年自洽）', () {
      // 2024 是闰年，3-1 之前的累计天数应含 2 月 29 天。
      final doy = DateTimeUtils.getDayOfYear(DateTime.utc(2024, 3, 1));
      // Jan(31) + Feb(29) = 60；day=1 → 60。
      expect(doy, 61);
      // 平年同日：Jan(31)+Feb(28)=59；day=1 → 60。
      expect(DateTimeUtils.getDayOfYear(DateTime.utc(2025, 3, 1)), 60);
    });
  });

  // C1.4 — nextMonth 返回 DateTime（与 nextDay/previousDay/nextYear/previousYear 一致）。
  //        BREAKING: 旧实现返回 int（月份编号）。
  group('C1.4 nextMonth returns DateTime', () {
    test('月中旬 → 下月同日', () {
      expect(DateTimeUtils.nextMonth(DateTime(2026, 1, 15)),
          DateTime(2026, 2, 15));
    });

    test('12 月 → 次年 1 月同日', () {
      expect(DateTimeUtils.nextMonth(DateTime(2026, 12, 10)),
          DateTime(2027, 1, 10));
    });

    test('月末溢出按下月末日收敛（1-31 → 2-28）', () {
      expect(DateTimeUtils.nextMonth(DateTime(2026, 1, 31)),
          DateTime(2026, 2, 28));
    });

    test('闰年 1-31 → 2-29', () {
      expect(DateTimeUtils.nextMonth(DateTime(2024, 1, 31)),
          DateTime(2024, 2, 29));
    });

    test('返回值是 DateTime 类型（不是 int）', () {
      expect(DateTimeUtils.nextMonth(DateTime(2026, 1, 15)), isA<DateTime>());
      expect(DateTimeUtils.nextMonth(DateTime(2026, 1, 15)), isNot(isA<int>()));
    });
  });

  // C1.5 — DateFormats 全部 static const（编译期常量）。
  group('C1.5 DateFormats const', () {
    test('常用格式存在且为 String 常量', () {
      expect(DateFormats.FULL, 'yyyy-MM-dd HH:mm:ss');
      expect(DateFormats.PARAM_FULL, 'yyyy/MM/dd HH:mm:ss');
      expect(DateFormats.ZH_FULL, 'yyyy年MM月dd日 HH时mm分ss秒');
    });
  });

  // C1.6 — monthDays 只读（const 不可变）。
  group('C1.6 monthDays read-only', () {
    test('可以按月号查天数', () {
      expect(monthDays[1], 31);
      expect(monthDays[2], 28);
      expect(monthDays[4], 30);
    });

    test('运行时不可变（const Map 写入抛 UnsupportedError）', () {
      expect(() => monthDays[13] = 30, throwsUnsupportedError);
    });
  });
}
