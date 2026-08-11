// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 正则校验：[RegexUtils] 实例方法（工厂单例）+ [StringExt] 手机号扩展。
class RegexDemo extends StatelessWidget {
  const RegexDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: '正则校验',
      children: [
        DemoRow(
          title: '邮箱校验',
          expr: "RegexUtils().isEmail('a@b.com')",
          result: RegexUtils().isEmail('a@b.com').toString(),
        ),
        DemoRow(
          title: '整数校验',
          expr: "RegexUtils().isInteger('123')",
          result: RegexUtils().isInteger('123').toString(),
        ),
        DemoRow(
          title: '18 位身份证（含校验位，末尾大小写 x 均可）',
          expr: "RegexUtils().isIDCard('11010519491231002X')",
          result: RegexUtils().isIDCard('11010519491231002X').toString(),
        ),
        DemoRow(
          title: '中国大陆手机号（String 扩展）',
          expr: "'13812345678'.isValidChineseMobile",
          result: '13812345678'.isValidChineseMobile.toString(),
        ),
      ],
    );
  }
}
