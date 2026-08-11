// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:cutils/cutils.dart';

// Project imports:
import 'demo_base.dart';

/// 字符串扩展：[StringExt] reverse / maskMobile / hideNumber / thousandSeparated。
class ExtDemo extends StatelessWidget {
  const ExtDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '字符串 / 数值扩展',
      children: [
        DemoRow(
          title: '反转字符串',
          expr: "'hello'.reverse()",
          result: 'hello'.reverse(),
        ),
        DemoRow(
          title: '手机号脱敏（11 位生效，maskMobile）',
          expr: "'13812345678'.maskMobile",
          result: '13812345678'.maskMobile,
        ),
        DemoRow(
          title: '隐藏中间位（hideNumber，可自定义区间）',
          expr: "'13800138000'.hideNumber()",
          result: '13800138000'.hideNumber(),
        ),
        DemoRow(
          title: '千分位（thousandSeparated）',
          expr: "'123456789.01'.thousandSeparated",
          result: '123456789.01'.thousandSeparated,
        ),
      ],
    );
  }
}
