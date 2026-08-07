import 'package:cutils/datetime/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DateTimeUtils 类存在且可格式化', () {
    final dt = DateTime(2026, 8, 7, 9, 30, 5);
    expect(
      dateTimeUtils.formatDate(dt, format: 'yyyy-MM-dd HH:mm:ss'),
      '2026-08-07 09:30:05',
    );
  });
}
