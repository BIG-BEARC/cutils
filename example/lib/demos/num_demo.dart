// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 数值与金额：[NumUtils] 精确运算、[MoneyUtils] 分→元、[IntFormating] 百分比。
class NumDemo extends StatelessWidget {
  const NumDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '数值与金额',
      children: [
        DemoRow(
          title: '精确相加（返回 Decimal）',
          expr: 'NumUtils.addDec(0.1, 0.2)',
          result: '${NumUtils.addDec(0.1, 0.2)}',
        ),
        DemoRow(
          title: '字符串精确相加（精度最高）',
          expr: "NumUtils.addDecString('0.1', '0.2')",
          result: '${NumUtils.addDecString('0.1', '0.2')}',
        ),
        DemoRow(
          title: '相加返回 double（最终 .toDouble）',
          expr: 'NumUtils.addNum(0.1, 0.2)',
          result: '${NumUtils.addNum(0.1, 0.2)}',
        ),
        DemoRow(
          title: '分 → 元（NORMAL 两位小数）',
          expr: 'MoneyUtils().changeF2Y(12345)',
          result: MoneyUtils().changeF2Y(12345),
        ),
        DemoRow(
          title: '分 → 元（带人民币符号）',
          expr: 'MoneyUtils().changeF2YWithUnit(12345, unit: MoneyUnit.YUAN)',
          result:
              MoneyUtils().changeF2YWithUnit(12345, unit: MoneyUnit.YUAN),
        ),
        DemoRow(
          title: '百分比格式化（int 扩展，视为比率×100）',
          expr: '(1).percentFormat',
          result: (1).percentFormat,
        ),
      ],
    );
  }
}
