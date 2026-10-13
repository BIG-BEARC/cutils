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

  test('barrel 导出 saas_pos 吸收批（version / lan / 脱敏扩展锚）', () {
    expect(VersionUtils.compare, isNotNull);
    expect(VersionUtils.isNewer, isNotNull);
    expect(LanUtils.pickBestLanIpv4, isNotNull);
    expect('13812345678'.maskMobile, isNotNull);
    expect('13812345678'.maskMobileOr(), isNotNull);
    expect('13812345678'.maskMiddle(head: 3, tail: 4), isNotNull);
    expect('13812345678'.maskMiddleOr(head: 3, tail: 4), isNotNull);
    expect(DateTimeUtils.getBusinessDate, isNotNull);
    expect(CryptoUtils.encodeSha256, isNotNull);
    expect(CryptoUtils.encodeHmacSha1, isNotNull);
    expect(CryptoUtils.encodeHmacSha256, isNotNull);
  });
}
