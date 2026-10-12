import 'package:cutils/cutils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel 导出关键公开符号', () {
    expect(DateTimeUtils, isNotNull);
    expect(NumUtils, isNotNull);
    expect(CryptoUtils, isNotNull);
    expect(logCollector, isNotNull);
  });

  test('barrel 导出 byte 模块与 changeY2F（吸收批次锚）', () {
    expect(ByteUtils, isNotNull);
    expect(ByteWord, isNotNull);
    expect(ByteDoubleWord, isNotNull);
    expect(Radix, isNotNull);
    expect(MoneyUtils.changeY2F, isNotNull);
  });
}
