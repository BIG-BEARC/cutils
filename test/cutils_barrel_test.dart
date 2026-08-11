import 'package:cutils/cutils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel 导出关键公开符号', () {
    expect(DateTimeUtils, isNotNull);
    expect(NumUtils, isNotNull);
    expect(CryptoUtils, isNotNull);
    expect(logCollector, isNotNull);
  });
}
