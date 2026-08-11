import 'package:cutils/datetime/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DateTimeUtils 类存在且可格式化', () {
    final dt = DateTime(2026, 8, 7, 9, 30, 5);
    expect(
      DateTimeUtils.formatDate(dt, format: 'yyyy-MM-dd HH:mm:ss'),
      '2026-08-07 09:30:05',
    );
  });

  // F1 — SSS milliseconds must always be 3 digits.
  group('F1 SSS millisecond format', () {
    test('ms < 10 pads to 3 digits', () {
      final dt = DateTime(2026, 8, 7, 9, 30, 5, 5);
      expect(DateTimeUtils.formatDate(dt, format: 'SSS'), '005');
    });

    test('ms < 100 pads to 3 digits', () {
      final dt = DateTime(2026, 8, 7, 9, 30, 5, 50);
      expect(DateTimeUtils.formatDate(dt, format: 'SSS'), '050');
    });

    test('ms >= 100 stays 3 digits', () {
      final dt = DateTime(2026, 8, 7, 9, 30, 5, 123);
      expect(DateTimeUtils.formatDate(dt, format: 'SSS'), '123');
    });

    test('SSS composes correctly inside a full format string', () {
      final dt = DateTime(2026, 8, 7, 9, 30, 5, 5);
      expect(
        DateTimeUtils.formatDate(dt, format: 'yyyy-MM-dd HH:mm:ss.SSS'),
        '2026-08-07 09:30:05.005',
      );
    });
  });

  // F2 — isToday must honor isUtc when locMs is supplied.
  group('F2 isToday honors isUtc in locMs branch', () {
    test('UTC boundary instant agrees with same-zone UTC now', () {
      // An instant near the UTC midnight boundary whose UTC calendar day
      // differs from its local calendar day in most non-UTC zones.
      // 2026-08-07 23:30 UTC.
      final utcMs = DateTime.utc(2026, 8, 7, 23, 30).millisecondsSinceEpoch;

      // isUtc:true → both `old` and `now` constructed in UTC, so the
      // day comparison is consistent regardless of the host's local zone.
      final isUtcToday = DateTimeUtils.isToday(
        utcMs,
        isUtc: true,
        locMs: utcMs,
      );

      // Reference: same zone (UTC) comparison via DateTime directly.
      final nowUtc = DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);
      final oldUtc = DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);
      final reference = nowUtc.year == oldUtc.year &&
          nowUtc.month == oldUtc.month &&
          nowUtc.day == oldUtc.day;

      expect(isUtcToday, isTrue);
      expect(isUtcToday, reference);
    });

    test('local (isUtc:false) locMs branch still works for a local instant',
        () {
      final localMs = DateTime(2026, 8, 7, 12, 0).millisecondsSinceEpoch;
      expect(
        DateTimeUtils.isToday(localMs, isUtc: false, locMs: localMs),
        isTrue,
      );
    });
  });
}
