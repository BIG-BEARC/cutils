import 'package:cutils/datetime/date_utils.dart';

import 'abs_time_info.dart';
import 'day_format.dart';
import 'en_info.dart';
import 'en_normal_info.dart';
import 'zh_info.dart';
import 'zh_normal_info.dart';

final Map<String, TimelineInfo> _timelineInfoMap = {
  'zh': ZhInfo(),
  'en': EnInfo(),
  'zh_normal': ZhNormalInfo(), //keepTwoDays() => false
  'en_normal': EnNormalInfo(), //keepTwoDays() => false
};

/// add custom configuration.
///
/// [locale] / [timelineInfo] 为非空类型（sound null-safety 下编译期保证）；
/// 不再使用 `ArgumentError.checkNotNull`（该 API 已废弃且在空安全下是死代码）。
void setLocaleInfo(String locale, TimelineInfo timelineInfo) {
  _timelineInfoMap[locale] = timelineInfo;
}

/// TimelineUtil
///
/// 把时间戳渲染成「刚刚 / x 分钟前 / 昨天 / MM-dd / yyyy-MM-dd」等时间线文案。
/// 文案随 [TimelineInfo] locale（默认 `'en'`）变化，可用 [setLocaleInfo] 注册
/// 自定义 locale。所有比较一致地用 [isUtc] 参数控制按 UTC 还是 local 解读。
class TimelineUtil {
  /// format time by DateTime.
  /// dateTime
  /// locDateTime: current time or schedule time.
  /// locale: output key.
  /// isUtc: 是否按 UTC 解读毫秒（线程到日历比较/格式化，默认 false=local）。
  static String formatByDateTime(
    DateTime dateTime, {
    DateTime? locDateTime,
    String? locale,
    DayFormat? dayFormat,
  }) {
    return format(
      dateTime.millisecondsSinceEpoch,
      locTimeMs: locDateTime?.millisecondsSinceEpoch,
      locale: locale,
      dayFormat: dayFormat,
      isUtc: dateTime.isUtc,
    );
  }

  /// format time by millis.
  /// dateTime : millis.
  /// locDateTime: current time or schedule time. millis.
  /// locale: output key.
  /// isUtc: 是否按 UTC 解读 [ms]/[locTimeMs]（影响日历日判定与格式化输出）。
  static String format(
    int ms, {
    int? locTimeMs,
    String? locale,
    DayFormat? dayFormat,
    bool isUtc = false,
  }) {
    int nowMs = locTimeMs ?? DateTime.now().millisecondsSinceEpoch;
    String useLocale = locale ?? 'en';
    TimelineInfo info = _timelineInfoMap[useLocale] ?? EnInfo();
    DayFormat useDayFormat = dayFormat ?? DayFormat.common;

    int elapsed = nowMs - ms;
    // 方向由 elapsed 符号决定，不靠 suffixAgo()==suffixAfter() 字符串比较
    // （某些 locale 两者相等会导致判定漏判）。
    final bool isFuture = elapsed < 0;
    String suffix;
    if (isFuture) {
      suffix = info.suffixAfter();
      // suffix after is empty. user just now.
      if (suffix.isNotEmpty) {
        elapsed = elapsed.abs();
        useDayFormat = DayFormat.simple;
      } else {
        return info.lessThanOneMinute();
      }
    } else {
      suffix = info.suffixAgo();
    }

    String timeline;
    if (info.customYesterday().isNotEmpty &&
        DateTimeUtils.isYesterdayByMs(ms, nowMs, isUtc: isUtc)) {
      return _getYesterday(ms, info, useDayFormat, isUtc: isUtc);
    }

    if (!DateTimeUtils.yearIsEqualByMs(ms, nowMs, isUtc: isUtc)) {
      timeline = _getYear(ms, useDayFormat, isUtc: isUtc);
      if (timeline.isNotEmpty) return timeline;
    }

    final num seconds = elapsed / 1000;
    final num minutes = seconds / 60;
    final num hours = minutes / 60;
    final num days = hours / 24;

    if (seconds < 90) {
      timeline = info.oneMinute(1);
      // 过去近况（非未来）才可能显示 "刚刚/just now"。
      if (!isFuture &&
          info.lessThanOneMinute().isNotEmpty &&
          seconds < info.maxJustNowSecond()) {
        timeline = info.lessThanOneMinute();
        suffix = '';
      }
    } else if (minutes < 60) {
      timeline = info.minutes(minutes.round());
    } else if (minutes < 90) {
      timeline = info.anHour(1);
    } else if (hours < 24) {
      timeline = info.hours(hours.round());
    } else {
      if ((days.round() == 1 && info.keepOneDay()) ||
          (days.round() == 2 && info.keepTwoDays())) {
        useDayFormat = DayFormat.simple;
      }
      timeline =
          _formatDays(ms, days.round(), info, useDayFormat, isUtc: isUtc);
      suffix = (useDayFormat == DayFormat.simple ? suffix : '');
    }
    return timeline + suffix;
  }

  /// Timeline like QQ.
  ///
  /// today (HH:mm)
  /// yesterday (昨天;Yesterday)
  /// this week (星期一,周一;Monday,Mon)
  /// others (yyyy-MM-dd)
  ///
  /// 未来日期（[ms] > 当前）：按 [formatToday]（默认 `HH:mm`）格式化返回，
  /// 即使该未来日期不是"今天"。这是既有约定行为（文档化，非变更）。
  ///
  /// [isUtc] 是否按 UTC 解读 [ms]/[locMs]（线程到 isToday/isYesterdayByMs/
  /// isWeek/formatDateMs，默认 false=local）。
  static String formatA(
    int ms, {
    int? locMs,
    String formatToday = 'HH:mm',
    String format = 'yyyy-MM-dd',
    String languageCode = 'en',
    bool short = false,
    bool isUtc = false,
  }) {
    int locTimeMs = locMs ?? DateTime.now().millisecondsSinceEpoch;
    int elapsed = locTimeMs - ms;
    if (elapsed < 0) {
      // 文档化：未来日期返回 formatToday（HH:mm），即使不是今天。
      return DateTimeUtils.formatDateMs(ms, format: formatToday, isUtc: isUtc);
    }

    if (DateTimeUtils.isToday(ms, isUtc: isUtc, locMs: locTimeMs)) {
      return DateTimeUtils.formatDateMs(ms, format: formatToday, isUtc: isUtc);
    }

    if (DateTimeUtils.isYesterdayByMs(ms, locTimeMs, isUtc: isUtc)) {
      return languageCode == 'zh' ? '昨天' : 'Yesterday';
    }

    if (DateTimeUtils.isWeek(ms, isUtc: isUtc, locMs: locTimeMs)) {
      return DateTimeUtils.getWeekdayByMs(ms,
          languageCode: languageCode, short: short, isUtc: isUtc);
    }

    return DateTimeUtils.formatDateMs(ms, format: format, isUtc: isUtc);
  }

  /// get Yesterday.
  /// 获取昨天.
  static String _getYesterday(
    int ms,
    TimelineInfo info,
    DayFormat dayFormat, {
    bool isUtc = false,
  }) {
    return info.customYesterday() +
        (dayFormat == DayFormat.full
            ? (' ${DateTimeUtils.formatDateMs(ms, format: 'HH:mm', isUtc: isUtc)}')
            : '');
  }

  /// get is not year info.
  /// 获取非今年信息.
  static String _getYear(
    int ms,
    DayFormat dayFormat, {
    bool isUtc = false,
  }) {
    if (dayFormat != DayFormat.simple) {
      return DateTimeUtils.formatDateMs(ms,
          format: (dayFormat == DayFormat.common
              ? 'yyyy-MM-dd'
              : 'yyyy-MM-dd HH:mm'),
          isUtc: isUtc);
    }
    return '';
  }

  /// format Days.
  static String _formatDays(
    int ms,
    num days,
    TimelineInfo info,
    DayFormat dayFormat, {
    bool isUtc = false,
  }) {
    String timeline;
    switch (dayFormat) {
      case DayFormat.simple:
        timeline = (days == 1
            ? info.customYesterday().isEmpty
                ? info.oneDay(days.round())
                : info.days(2)
            : info.days(days.round()));
        break;
      case DayFormat.common:
        timeline =
            DateTimeUtils.formatDateMs(ms, format: 'MM-dd', isUtc: isUtc);
        break;
      case DayFormat.full:
        timeline =
            DateTimeUtils.formatDateMs(ms, format: 'MM-dd HH:mm', isUtc: isUtc);
        break;
    }
    return timeline;
  }
}
