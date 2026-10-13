// getBusinessDate — absorbed (as capability, rewritten) from
// saas_pos_smart_edition `lib/shared/utils/business_time_utils.dart`.
//
// Strict TDD: written first. Deviations from the source on purpose:
// - invalid cutoff strings throw ArgumentError instead of being silently
//   swallowed (cutils not-silent baseline);
// - the result is the cutoff instant itself (not midnight) — callers get
//   an unambiguous "business day anchor" they can format or compare.

import 'package:cutils/datetime/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B1 无截止线', () {
    test('返回结账时刻（原值相等）', () {
      final t = DateTime(2026, 10, 12, 15, 30);
      expect(DateTimeUtils.getBusinessDate(checkoutTime: t), t);
    });
  });

  group('B2 归属规则（返回截止时刻，非日界 00:00）', () {
    test('结账晚于截止线 → 归当天截止时刻', () {
      final got = DateTimeUtils.getBusinessDate(
        checkoutTime: DateTime(2026, 10, 12, 23, 0, 0),
        cutoffTime: '04:00:00',
      );
      expect(got, DateTime(2026, 10, 12, 4, 0, 0));
    });

    test('结账早于截止线 → 归前一天截止时刻', () {
      final got = DateTimeUtils.getBusinessDate(
        checkoutTime: DateTime(2026, 10, 12, 3, 0, 0),
        cutoffTime: '04:00:00',
      );
      expect(got, DateTime(2026, 10, 11, 4, 0, 0));
    });

    test('恰等于截止线 → 归当天（含等于）', () {
      final got = DateTimeUtils.getBusinessDate(
        checkoutTime: DateTime(2026, 10, 12, 4, 0, 0),
        cutoffTime: '04:00:00',
      );
      expect(got, DateTime(2026, 10, 12, 4, 0, 0));
    });

    test('跨月回退（10 月 1 日凌晨 → 9 月 30 日）', () {
      final got = DateTimeUtils.getBusinessDate(
        checkoutTime: DateTime(2026, 10, 1, 2, 0, 0),
        cutoffTime: '04:00:00',
      );
      expect(got, DateTime(2026, 9, 30, 4, 0, 0));
    });

    test('跨年回退（1 月 1 日凌晨 → 上年 12 月 31 日）', () {
      final got = DateTimeUtils.getBusinessDate(
        checkoutTime: DateTime(2026, 1, 1, 2, 0, 0),
        cutoffTime: '04:00:00',
      );
      expect(got, DateTime(2025, 12, 31, 4, 0, 0));
    });
  });

  group('B3 非法截止线抛 ArgumentError（不静默基线）', () {
    test('段数不是 3', () {
      expect(
        () => DateTimeUtils.getBusinessDate(
          checkoutTime: DateTime(2026, 10, 12, 3),
          cutoffTime: '04:00',
        ),
        throwsArgumentError,
      );
      expect(
        () => DateTimeUtils.getBusinessDate(
          checkoutTime: DateTime(2026, 10, 12, 3),
          cutoffTime: '04:00:00.000',
        ),
        throwsArgumentError,
      );
    });

    test('段值非法（非数字 / 越界）', () {
      expect(
        () => DateTimeUtils.getBusinessDate(
          checkoutTime: DateTime(2026, 10, 12, 3),
          cutoffTime: 'ab:00:00',
        ),
        throwsArgumentError,
      );
      expect(
        () => DateTimeUtils.getBusinessDate(
          checkoutTime: DateTime(2026, 10, 12, 3),
          cutoffTime: '25:00:00',
        ),
        throwsArgumentError,
      );
      expect(
        () => DateTimeUtils.getBusinessDate(
          checkoutTime: DateTime(2026, 10, 12, 3),
          cutoffTime: '04:60:00',
        ),
        throwsArgumentError,
      );
      expect(
        () => DateTimeUtils.getBusinessDate(
          checkoutTime: DateTime(2026, 10, 12, 3),
          cutoffTime: '04:00:60',
        ),
        throwsArgumentError,
      );
    });
  });
}
