// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 标识生成：[RandomUtils] 随机串 / [UuidUtils] v1 / v4。
class IdentifierDemo extends StatelessWidget {
  const IdentifierDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final rs = RandomUtils.randomString(length: 8);
    final v1 = UuidUtils.generateV1();
    final v4 = UuidUtils.generateV4();

    return DemoScaffold(
      title: '标识生成',
      children: [
        DemoRow(
          title: '随机字符串（定长 8）',
          expr: 'RandomUtils.randomString(length: 8)',
          result: rs,
        ),
        DemoRow(
          title: 'UUID v1（基于时间）',
          expr: 'UuidUtils.generateV1()',
          result: v1,
        ),
        DemoRow(
          title: 'UUID v4（基于随机数）',
          expr: 'UuidUtils.generateV4()',
          result: v4,
        ),
      ],
    );
  }
}
