// Package imports:
import 'package:cutils/cutils.dart';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'demo_base.dart';

/// 日期时间：[DateTimeUtils] 格式化 / 今日判定 / 星期，[TimelineUtil] 时间线文案。
class DatetimeDemo extends StatelessWidget {
  const DatetimeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    return DemoScaffold(
      title: '日期时间',
      children: [
        DemoRow(
          title: '格式化当前时间',
          expr:
              "DateTimeUtils.formatDate(DateTime.now(), format: 'yyyy-MM-dd HH:mm:ss')",
          result: DateTimeUtils.formatDate(now,
              format: 'yyyy-MM-dd HH:mm:ss'),
        ),
        DemoRow(
          title: '是否是今天（按毫秒）',
          expr: 'DateTimeUtils.isToday(DateTime.now().millisecondsSinceEpoch)',
          result: DateTimeUtils.isToday(now.millisecondsSinceEpoch).toString(),
        ),
        DemoRow(
          title: '获取星期（中文）',
          expr: "DateTimeUtils.getWeekday(DateTime.now(), languageCode: 'zh')",
          result: DateTimeUtils.getWeekday(now, languageCode: 'zh'),
        ),
        DemoRow(
          title: '时间线文案（2 小时前，中文）',
          expr: "TimelineUtil.formatByDateTime(2小时前, locale: 'zh')",
          result: TimelineUtil.formatByDateTime(twoHoursAgo, locale: 'zh'),
        ),
        DemoRow(
          title: 'QQ 风格时间线（2 天前）',
          expr: "TimelineUtil.formatA(2天前的毫秒, languageCode: 'zh')",
          result: TimelineUtil.formatA(twoDaysAgo.millisecondsSinceEpoch,
              languageCode: 'zh'),
        ),
      ],
    );
  }
}
