// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 加解密：[CryptoUtils] MD5 / Base64 / XOR（含往返）。
class CryptoDemo extends StatelessWidget {
  const CryptoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const src = 'hello';
    const xorKey = '1,2,3';

    final md5Hex = CryptoUtils.encodeMd5(src);
    final b64 = CryptoUtils.encodeBase64(src);
    final b64Back = CryptoUtils.decodeBase64(b64);
    // xorCode 自反：连续两次还原。
    final xoredRoundTrip =
        CryptoUtils.xorCode(CryptoUtils.xorCode(src, xorKey), xorKey);
    // 字节级 XOR + Base64 往返（不会落入代理对区间）。
    final b64Xor = CryptoUtils.xorBase64Encode(src, xorKey);
    final b64XorBack = CryptoUtils.xorBase64Decode(b64Xor, xorKey);

    return DemoScaffold(
      title: '加解密',
      children: [
        DemoRow(
          title: 'MD5',
          expr: "CryptoUtils.encodeMd5('hello')",
          result: md5Hex,
        ),
        DemoRow(
          title: 'Base64 编码',
          expr: "CryptoUtils.encodeBase64('hello')",
          result: b64,
        ),
        DemoRow(
          title: 'Base64 解码（往返）',
          expr: "CryptoUtils.decodeBase64(上一步)",
          result: b64Back,
        ),
        DemoRow(
          title: 'XOR 自反（xorCode 两次还原）',
          expr: "CryptoUtils.xorCode(CryptoUtils.xorCode('hello','1,2,3'),'1,2,3')",
          result: xoredRoundTrip,
        ),
        DemoRow(
          title: 'XOR + Base64 往返（字节级，安全）',
          expr: 'xorBase64Encode → xorBase64Decode',
          result: '$b64Xor  →  $b64XorBack',
        ),
      ],
    );
  }
}
