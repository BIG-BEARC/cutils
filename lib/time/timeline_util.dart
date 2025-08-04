import 'package:cutils/date/date_utils.dart';

import 'abs_time_info.dart';
import 'day_format.dart';
import 'en_info.dart';
import 'en_normal_info.dart';
import 'zh_info.dart';
import 'zh_normal_info.dart';

Map<String, TimelineInfo> _timelineInfoMap = {
  'zh': ZhInfo(),
  'en': EnInfo(),
  'zh_normal': ZhNormalInfo(), //keepTwoDays() => false
  'en_normal': EnNormalInfo(), //keepTwoDays() => false
};

/// add custom configuration.
void setLocaleInfo(String locale, TimelineInfo timelineInfo) {
  ArgumentError.checkNotNull(locale, '[locale] must not be null');
  ArgumentError.checkNotNull(timelineInfo, '[timelineInfo] must not be null');
  _timelineInfoMap[locale] = timelineInfo;
}

/// TimelineUtil
class TimelineUtil {
  /// format time by DateTime.
  /// dateTime
  /// locDateTime: current time or schedule time.
  /// locale: output key.
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
    );
  }

  /// format time by millis.
  /// dateTime : millis.
  /// locDateTime: current time or schedule time. millis.
  /// locale: output key.
  static String format(
    int ms, {
    int? locTimeMs,
    String? locale,
    DayFormat? dayFormat,
  }) {
    int nowMs = locTimeMs ?? DateTime.now().millisecondsSinceEpoch;
    String useLocale = locale ?? 'en';
    TimelineInfo info = _timelineInfoMap[useLocale] ?? EnInfo();
    DayFormat useDayFormat = dayFormat ?? DayFormat.common;

    int elapsed = nowMs - ms;
    String suffix;
    if (elapsed < 0) {
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
    if (info.customYesterday().isNotEmpty && dateUtils.isYesterdayByMs(ms, nowMs)) {
      return _getYesterday(ms, info, useDayFormat);
    }

    if (!dateUtils.yearIsEqualByMs(ms, nowMs)) {
      timeline = _getYear(ms, useDayFormat);
      if (timeline.isNotEmpty) return timeline;
    }

    final num seconds = elapsed / 1000;
    final num minutes = seconds / 60;
    final num hours = minutes / 60;
    final num days = hours / 24;

    if (seconds < 90) {
      timeline = info.oneMinute(1);
      if (suffix != info.suffixAfter() && info.lessThanOneMinute().isNotEmpty && seconds < info.maxJustNowSecond()) {
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
      if ((days.round() == 1 && info.keepOneDay() == true) || (days.round() == 2 && info.keepTwoDays() == true)) {
        useDayFormat = DayFormat.simple;
      }
      timeline = _formatDays(ms, days.round(), info, useDayFormat);
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
  static String formatA(
    int ms, {
    int? locMs,
    String formatToday = 'HH:mm',
    String format = 'yyyy-MM-dd',
    String languageCode = 'en',
    bool short = false,
  }) {
    int locTimeMs = locMs ?? DateTime.now().millisecondsSinceEpoch;
    int elapsed = locTimeMs - ms;
    if (elapsed < 0) {
      return dateUtils.formatDateMs(ms, format: formatToday);
    }

    if (dateUtils.isToday(ms, locMs: locTimeMs)) {
      return dateUtils.formatDateMs(ms, format: formatToday);
    }

    if (dateUtils.isYesterdayByMs(ms, locTimeMs)) {
      return languageCode == 'zh' ? '昨天' : 'Yesterday';
    }

    if (dateUtils.isWeek(ms, locMs: locTimeMs)) {
      return dateUtils.getWeekdayByMs(ms, languageCode: languageCode, short: short);
    }

    return dateUtils.formatDateMs(ms, format: format);
  }

  /// get Yesterday.
  /// 获取昨天.
  static String _getYesterday(
    int ms,
    TimelineInfo info,
    DayFormat dayFormat,
  ) {
    return info.customYesterday() + (dayFormat == DayFormat.full ? (' ${dateUtils.formatDateMs(ms, format: 'HH:mm')}') : '');
  }

  /// get is not year info.
  /// 获取非今年信息.
  static String _getYear(
    int ms,
    DayFormat dayFormat,
  ) {
    if (dayFormat != DayFormat.simple) {
      return dateUtils.formatDateMs(ms, format: (dayFormat == DayFormat.common ? 'yyyy-MM-dd' : 'yyyy-MM-dd HH:mm'));
    }
    return '';
  }

  /// format Days.
  static String _formatDays(
    int ms,
    num days,
    TimelineInfo info,
    DayFormat dayFormat,
  ) {
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
        timeline = dateUtils.formatDateMs(ms, format: 'MM-dd');
        break;
      case DayFormat.full:
        timeline = dateUtils.formatDateMs(ms, format: 'MM-dd HH:mm');
        break;
    }
    return timeline;
  }
}
