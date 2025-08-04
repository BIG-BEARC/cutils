
import 'data_formats.dart';

/// * @Author: chuxiong
/// * @Created at: 23-07-2025 16:58
/// * @Email:
/// * description
final dateUtils = DateUtils();

class DateUtils {
  DateUtils._();

  static final DateUtils _instance = DateUtils._();

  factory DateUtils() => _instance;

  /// get DateTime By DateStr.
  /// 将字符串时间转化为DateTime
  DateTime? getDateTime(String dateStr, {bool? isUtc}) {
    DateTime? dateTime = DateTime.tryParse(dateStr);
    if (isUtc != null) {
      if (isUtc) {
        dateTime = dateTime?.toUtc();
      } else {
        dateTime = dateTime?.toLocal();
      }
    }
    return dateTime;
  }

  /// get DateTime By Milliseconds.
  /// 将毫秒时间转化为DateTime
  DateTime getDateTimeByMs(int ms, {bool isUtc = false}) {
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc);
  }

  /// get DateMilliseconds By DateStr.
  /// 将字符串时间转化为毫秒值
  int? getDateMsByTimeStr(String dateStr, {bool? isUtc}) {
    DateTime? dateTime = getDateTime(dateStr, isUtc: isUtc);
    return dateTime?.millisecondsSinceEpoch;
  }

  /// get Now Date Milliseconds.
  /// 获取当前毫秒值
  int getNowDateMs() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// get Now Date Str.(yyyy-MM-dd HH:mm:ss)
  ///  获取现在日期字符串，默认是：yyyy-MM-dd HH:mm:ss
  String getNowDateStr() {
    return formatDate(DateTime.now());
  }

  /// 获取当前日期返回DateTime(utc)
  DateTime getNowUtcDateTime() {
    return DateTime.now().toUtc();
  }

  /// 获取昨天日期返回DateTime
  DateTime getYesterday() {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch - 24 * 60 * 60 * 1000,
    );
    return dateTime;
  }

  /// format date by milliseconds.
  /// 格式化日期毫秒时间
  String formatDateMs(int ms, {bool isUtc = false, String? format}) {
    return formatDate(getDateTimeByMs(ms, isUtc: isUtc), format: format);
  }

  /// 获取当前日期，返回指定格式
  String getNowDateTimeFormat(String outFormat) {
    var formatResult = formatDate(DateTime.now(), format: outFormat);
    return formatResult;
  }

  /// 获取当前日期，返回指定格式
  String getUtcDateTimeFormat(String outFormat) {
    var formatResult = formatDate(getNowUtcDateTime(), format: outFormat);
    return formatResult;
  }

  /// format date by date str.
  /// dateStr 日期字符串
  String formatDateStr(String dateStr, {bool? isUtc, String? format}) {
    return formatDate(getDateTime(dateStr, isUtc: isUtc), format: format);
  }

  /// format date by DateTime.
  /// format 转换格式(已提供常用格式 DateFormats，可以自定义格式：'yyyy/MM/dd HH:mm:ss')
  /// 格式要求
  /// year -> yyyy/yy   month -> MM/M    day -> dd/d
  /// hour -> HH/H      minute -> mm/m   second -> ss/s
  String formatDate(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';
    format = format ?? DateFormats.FULL;
    if (format.contains('yy')) {
      String year = dateTime.year.toString();
      if (format.contains('yyyy')) {
        format = format.replaceAll('yyyy', year);
      } else {
        format = format.replaceAll('yy', year.substring(year.length - 2, year.length));
      }
    }

    format = _comFormat(dateTime.month, format, 'M', 'MM');
    format = _comFormat(dateTime.day, format, 'd', 'dd');
    format = _comFormat(dateTime.hour, format, 'H', 'HH');
    format = _comFormat(dateTime.minute, format, 'm', 'mm');
    format = _comFormat(dateTime.second, format, 's', 'ss');
    format = _comFormat(dateTime.millisecond, format, 'S', 'SSS');

    return format;
  }

  /// com format.
  String _comFormat(int value, String format, String single, String full) {
    if (format.contains(single)) {
      if (format.contains(full)) {
        format = format.replaceAll(full, value < 10 ? '0$value' : value.toString());
      } else {
        format = format.replaceAll(single, value.toString());
      }
    }
    return format;
  }

  /// get WeekDay.
  /// dateTime
  /// isUtc
  /// languageCode zh or en
  /// short
  String getWeekday(DateTime? dateTime, {String languageCode = 'en', bool short = false}) {
    if (dateTime == null) return "";
    String weekday = "";
    switch (dateTime.weekday) {
      case 1:
        weekday = languageCode == 'zh' ? '星期一' : 'Monday';
        break;
      case 2:
        weekday = languageCode == 'zh' ? '星期二' : 'Tuesday';
        break;
      case 3:
        weekday = languageCode == 'zh' ? '星期三' : 'Wednesday';
        break;
      case 4:
        weekday = languageCode == 'zh' ? '星期四' : 'Thursday';
        break;
      case 5:
        weekday = languageCode == 'zh' ? '星期五' : 'Friday';
        break;
      case 6:
        weekday = languageCode == 'zh' ? '星期六' : 'Saturday';
        break;
      case 7:
        weekday = languageCode == 'zh' ? '星期日' : 'Sunday';
        break;
      default:
        break;
    }
    return languageCode == 'zh' ? (short ? weekday.replaceAll('星期', '周') : weekday) : weekday.substring(0, short ? 3 : weekday.length);
  }

  /// get WeekDay By Milliseconds.
  /// 获取毫秒值对应是星期几
  String getWeekdayByMs(
    int milliseconds, {
    bool isUtc = false,
    String languageCode = 'en',
    bool short = false,
  }) {
    DateTime dateTime = getDateTimeByMs(milliseconds, isUtc: isUtc);
    return getWeekday(dateTime, languageCode: languageCode, short: short);
  }

  /// get day of year.
  /// 在今年的第几天.
  int getDayOfYear(DateTime dateTime) {
    int year = dateTime.year;
    int month = dateTime.month;
    int days = dateTime.day;
    for (int i = 1; i < month; i++) {
      days = days + MONTH_DAY[i]!;
    }
    if (isLeapYearByYear(year) && month > 2) {
      days = days + 1;
    }
    return days;
  }

  /// get day of year.
  /// 在今年的第几天.
  int getDayOfYearByMs(int ms, {bool isUtc = false}) {
    return getDayOfYear(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc));
  }

  /// is today.
  /// 是否是当天.
  bool isToday(int? milliseconds, {bool isUtc = false, int? locMs}) {
    if (milliseconds == null || milliseconds == 0) return false;
    DateTime old = DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: isUtc);
    DateTime now;
    if (locMs != null) {
      now = getDateTimeByMs(locMs);
    } else {
      now = isUtc ? DateTime.now().toUtc() : DateTime.now().toLocal();
    }
    return old.year == now.year && old.month == now.month && old.day == now.day;
  }

  /// is yesterday by dateTime.
  /// 是否是昨天.
  bool isYesterday(DateTime dateTime, DateTime locDateTime) {
    if (yearIsEqual(dateTime, locDateTime)) {
      int spDay = getDayOfYear(locDateTime) - getDayOfYear(dateTime);
      return spDay == 1;
    } else {
      return ((locDateTime.year - dateTime.year == 1) && dateTime.month == 12 && locDateTime.month == 1 && dateTime.day == 31 && locDateTime.day == 1);
    }
  }

  /// is yesterday by millis.
  /// 是否是昨天.
  bool isYesterdayByMs(int ms, int locMs) {
    return isYesterday(DateTime.fromMillisecondsSinceEpoch(ms), DateTime.fromMillisecondsSinceEpoch(locMs));
  }

  /// is Week.
  /// 是否是本周.
  bool isWeek(int? ms, {bool isUtc = false, int? locMs}) {
    if (ms == null || ms <= 0) {
      return false;
    }
    DateTime old0 = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc);
    DateTime now0;
    if (locMs != null) {
      now0 = getDateTimeByMs(locMs, isUtc: isUtc);
    } else {
      now0 = isUtc ? DateTime.now().toUtc() : DateTime.now().toLocal();
    }

    DateTime old = now0.millisecondsSinceEpoch > old0.millisecondsSinceEpoch ? old0 : now0;
    DateTime now = now0.millisecondsSinceEpoch > old0.millisecondsSinceEpoch ? now0 : old0;
    return (now.weekday >= old.weekday) && (now.millisecondsSinceEpoch - old.millisecondsSinceEpoch <= 7 * 24 * 60 * 60 * 1000);
  }

  /// year is equal.
  /// 是否同年.
  bool yearIsEqual(DateTime dateTime, DateTime locDateTime) {
    return dateTime.year == locDateTime.year;
  }

  /// year is equal.
  /// 是否同年.
  bool yearIsEqualByMs(int ms, int locMs) {
    return yearIsEqual(DateTime.fromMillisecondsSinceEpoch(ms), DateTime.fromMillisecondsSinceEpoch(locMs));
  }

  /// Return whether it is leap year.
  /// 是否是闰年
  bool isLeapYear(DateTime dateTime) {
    return isLeapYearByYear(dateTime.year);
  }

  /// Return whether it is leap year.
  /// 是否是闰年
  bool isLeapYearByMilliseconds(int milliseconds) {
    var dateTime = getDateTimeByMs(milliseconds);
    return isLeapYearByYear(dateTime.year);
  }

  /// Return whether it is leap year.
  /// 是否是闰年
  bool isLeapYearByYear(int year) {
    return year % 4 == 0 && year % 100 != 0 || year % 400 == 0;
  }

  ///判断a和b两个时间是否是同一天
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns a number of the next month.
  int nextMonth(DateTime date) {
    final month = date.month;
    return month == DateTime.monthsPerYear ? 1 : month + 1;
  }

  /// Returns [DateTime] for the beginning of the day (00:00:00).
  ///
  /// (2020, 4, 9, 16, 50) -> (2020, 4, 9, 0, 0)
  DateTime startOfDay(DateTime dateTime) => _date(dateTime.isUtc, dateTime.year, dateTime.month, dateTime.day);

  /// Returns [DateTime] for the beginning of the next day (00:00:00).
  ///
  /// (2020, 4, 9, 16, 50) -> (2020, 4, 10, 0, 0)
  DateTime startOfNextDay(DateTime dateTime) => _date(dateTime.isUtc, dateTime.year, dateTime.month, dateTime.day + 1);

  /// Returns [DateTime] for the beginning of today (00:00:00).
  DateTime startOfToday() => startOfDay(DateTime.now());

  /// Creates a copy of [date] but with time replaced with the new values.
  DateTime setTime(DateTime date, int hours, int minutes, [int seconds = 0, int milliseconds = 0, int microseconds = 0]) =>
      _date(date.isUtc, date.year, date.month, date.day, hours, minutes, seconds, milliseconds, microseconds);

  /// Creates a copy of [date] but with the given fields
  /// replaced with the new values.
  DateTime copyWith(DateTime date, {int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond, int? microsecond}) => _date(
      date.isUtc,
      year ?? date.year,
      month ?? date.month,
      day ?? date.day,
      hour ?? date.hour,
      minute ?? date.minute,
      second ?? date.second,
      millisecond ?? date.millisecond,
      microsecond ?? date.microsecond);

  /// Returns the [DateTime] resulting from adding the given number
  /// of months to this [DateTime].
  ///
  /// The result is computed by incrementing the month parts of this
  /// [DateTime] by months months, and, if required, adjusting the day part
  /// of the resulting date downwards to the last day of the resulting month.
  ///
  /// For example:
  /// (2020, 12, 31) -> add 2 months -> (2021, 2, 28).
  /// (2020, 12, 31) -> add 1 month -> (2021, 1, 31).
  DateTime addMonths(DateTime date, int months) {
    var res = copyWith(date, month: date.month + months);
    if (date.day != res.day) res = copyWith(res, day: 0);
    return res;
  }

  /// Returns week number in year.
  ///
  /// The first week of the year is the week that contains
  /// 4 or more days of that year (='First 4-day week').
  ///
  /// So if week contains less than 4 days - it's in another year.
  ///
  /// The highest week number in a year is either 52 or 53.
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday].
  int getWeekNumber(DateTime date, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    if (isWeekInYear(date, date.year, firstWeekday)) {
      final startOfTheFirstWeek = firstDayOfFirstWeek(date.year, firstWeekday: firstWeekday);
      final diffInDays = getDaysDifference(date, startOfTheFirstWeek);
      return (diffInDays / DateTime.daysPerWeek).floor() + 1;
    } else if (date.month == DateTime.december) {
      // first of the next year
      return 1;
    } else {
      // last of the previous year
      return getWeekNumber(DateTime(date.year - 1, DateTime.december, 31), firstWeekday: firstWeekday);
    }
  }

  /// Returns number of the last week in [year].
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday].
  ///
  /// See [getWeekNumber].
  int getLastWeekNumber(int year, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    final start = firstDayOfFirstWeek(year, firstWeekday: firstWeekday);
    final end = firstDayOfWeek(DateTime(year, DateTime.december, 31), firstWeekday: firstWeekday);
    final diffInDays = getDaysDifference(end, start);
    var res = diffInDays ~/ DateTime.daysPerWeek;
    if (isWeekInYear(end, year, firstWeekday)) res++;
    return res;
  }

  /// Returns number of the day in week (starting with 1).
  ///
  /// Difference from [DateTime.weekday] is that
  /// you can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday].
  ///
  int getDayNumberInWeek(DateTime date, {int firstWeekday = DateTime.monday}) {
    var res = date.weekday - (firstWeekday) + 1;
    if (res <= 0) res += DateTime.daysPerWeek;

    return res;
  }

  /// Returns number of the day in year.
  ///
  /// Starting with 1.
  int getDayNumberInYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, DateTime.january, 1);
    return getDaysDifference(date, firstDayOfYear) + 1;
  }

  /// Returns the number of days in a given year.
  int getDaysInYear(int year) {
    final lastDayOfYear = DateTime(year, DateTime.december, 31);
    return getDayNumberInYear(lastDayOfYear);
  }

  /// Returns count of days between two dates.
  ///
  /// Time will be ignored, so for the dates
  /// (2020, 11, 18, 16, 50) and (2020, 11, 19, 10, 00)
  /// result will be 1.
  ///
  /// Use this method for count days instead of
  /// `a.difference(b).inDays`, since it can return
  /// some unexpected result, because of daylight saving hour.
  int getDaysDifference(DateTime a, DateTime b) {
    final straight = a.isBefore(b);
    final start = startOfDay(straight ? a : b);
    final end = startOfDay(straight ? b : a).add(const Duration(hours: 12));
    final diff = end.difference(start);
    return diff.inHours ~/ 24;
  }

  /// Checks if [day] is in the first day of a week.
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday].
  bool isFirstDayOfWeek(DateTime day, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    return isSameDay(firstDayOfWeek(day, firstWeekday: firstWeekday), day);
  }

  /// Checks if [day] is in the last day of a week.
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday],
  /// so the last day will be [DateTime.sunday].
  bool isLastDayOfWeek(DateTime day, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    return isSameDay(lastDayOfWeek(day, firstWeekday: firstWeekday), day);
  }

  /// Checks if [day] is in the first day of a month.
  bool isFirstDayOfMonth(DateTime day) {
    return day.day == 1;
  }

  /// Checks if [day] is in the last day of a month.
  bool isLastDayOfMonth(DateTime day) {
    return nextDay(day).month != day.month;
  }

  /// Returns start of the first day of the week for specified [dateTime].
  ///
  /// For example: (2020, 4, 9, 15, 16) -> (2020, 4, 6, 0, 0, 0, 0).
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday].
  DateTime firstDayOfWeek(DateTime dateTime, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    var days = dateTime.weekday - (firstWeekday);
    if (days < 0) days += DateTime.daysPerWeek;

    return _date(dateTime.isUtc, dateTime.year, dateTime.month, dateTime.day - days);
  }

  /// Returns start of the first day of the first week in [year].
  ///
  /// For example: (2020, 4, 9, 15, 16) -> (2019, 12, 30, 0, 0, 0, 0).
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday].
  ///
  /// See [getWeekNumber].
  DateTime firstDayOfFirstWeek(int year, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    final startOfYear = DateTime(year);
    return isWeekInYear(startOfYear, year, firstWeekday)
        ? firstDayOfWeek(startOfYear, firstWeekday: firstWeekday)
        : firstDayOfNextWeek(startOfYear, firstWeekday: firstWeekday);
  }

  /// Returns start of the first day of the next week for specified [dateTime].
  ///
  /// For example: (2020, 4, 9, 15, 16) -> (2020, 4, 13, 0, 0, 0, 0).
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  /// By default it's [DateTime.monday].
  DateTime firstDayOfNextWeek(DateTime dateTime, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    var days = dateTime.weekday - (firstWeekday);
    if (days >= 0) days -= DateTime.daysPerWeek;
    return _date(dateTime.isUtc, dateTime.year, dateTime.month, dateTime.day - days);
  }

  /// Returns start of the last day of the week for specified [dateTime].
  ///
  /// For example: (2020, 4, 9, 15, 16) -> (2020, 4, 12, 0, 0, 0, 0).
  ///
  /// You can define first weekday (Monday, Sunday or Saturday) with
  /// parameter [firstWeekday]. It should be one of the constant values
  /// [DateTime.monday], ..., [DateTime.sunday].
  ///
  /// By default it's [DateTime.monday],
  /// so the last day will be [DateTime.sunday].
  DateTime lastDayOfWeek(DateTime dateTime, {int firstWeekday = DateTime.monday}) {
    assert(firstWeekday > 0 && firstWeekday < 8);

    var days = (firstWeekday) - 1 - dateTime.weekday;
    if (days < 0) days += DateTime.daysPerWeek;

    return _date(dateTime.isUtc, dateTime.year, dateTime.month, dateTime.day + days);
  }

  /// Returns [DateTime] that represents a beginning
  /// of the first day of the month containing [date].
  ///
  /// Example: (2020, 4, 9, 15, 16) -> (2020, 4, 1, 0, 0, 0, 0).
  DateTime firstDayOfMonth(DateTime date) {
    return _date(date.isUtc, date.year, date.month);
  }

  /// Returns [DateTime] that represents a beginning
  /// of the first day of the next month.
  ///
  /// Example: (2020, 4, 9, 15, 16) -> (2020, 5, 1, 0, 0, 0, 0).
  DateTime firstDayOfNextMonth(DateTime dateTime) {
    final month = dateTime.month;
    final year = dateTime.year;
    final nextMonthStart = (month < DateTime.monthsPerYear) ? _date(dateTime.isUtc, year, month + 1, 1) : _date(dateTime.isUtc, year + 1, 1, 1);
    return nextMonthStart;
  }

  /// Returns [DateTime] that represents a beginning
  /// of the last day of the month containing [date].
  ///
  /// Example: (2020, 4, 9, 15, 16) -> (2020, 4, 30, 0, 0, 0, 0).
  DateTime lastDayOfMonth(DateTime dateTime) {
    return previousDay(firstDayOfNextMonth(dateTime));
  }

  /// Returns [DateTime] that represents a beginning
  /// of the first day of the year containing [date].
  ///
  /// Example: (2020, 3, 9, 15, 16) -> (2020, 1, 1, 0, 0, 0, 0).
  DateTime firstDayOfYear(DateTime dateTime) {
    return _date(dateTime.isUtc, dateTime.year, 1, 1);
  }

  /// Returns [DateTime] that represents a beginning
  /// of the first day of the next year.
  ///
  /// Example: (2020, 3, 9, 15, 16) -> (2021, 1, 1, 0, 0, 0, 0).
  DateTime firstDayOfNextYear(DateTime dateTime) {
    return _date(dateTime.isUtc, dateTime.year + 1, 1, 1);
  }

  /// Returns [DateTime] that represents a beginning
  /// of the last day of the year containing [date].
  ///
  /// Example: (2020, 4, 9, 15, 16) -> (2020, 12, 31, 0, 0, 0, 0).
  DateTime lastDayOfYear(DateTime dateTime) {
    return _date(dateTime.isUtc, dateTime.year, DateTime.december, 31);
  }

  /// Проверяет является ли заданная дата текущей.
  bool isCurrentDate(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Returns number of days in the [month] of the [year].
  int getDaysInMonth(int year, int monthNum) {
    assert(monthNum > 0);
    assert(monthNum <= 12);
    return DateTime(year, monthNum + 1, 0).day;
  }

  /// Returns same time in the next day.
  DateTime nextDay(DateTime d) {
    return copyWith(d, day: d.day + 1);
  }

  /// Returns same time in the previous day.
  DateTime previousDay(DateTime d) {
    return copyWith(d, day: d.day - 1);
  }

  /// Returns same date in the next year.
  DateTime nextYear(DateTime d) {
    return _date(d.isUtc, d.year + 1, d.month, d.day);
  }

  /// Returns same date in the previous year.
  DateTime previousYear(DateTime d) {
    return _date(d.isUtc, d.year - 1, d.month, d.day);
  }

  /// Returns an iterable of [DateTime] with 1 day step in given range.
  ///
  /// [start] is the start of the rande, inclusive.
  /// [end] is the end of the range, exclusive.
  ///
  /// If [start] equals [end], than [start] still will be included in interbale.
  /// If [start] less than [end], than empty interable will be returned.
  ///
  /// [DateTime] in result uses [start] timezone.
  Iterable<DateTime> generateWithDayStep(DateTime start, DateTime end) sync* {
    if (end.isBefore(start)) return;

    var date = start;
    do {
      yield date;
      date = nextDay(date);
    } while (date.isBefore(end));
  }

  /// Checks if week, that contains [date] is in [year].
  bool isWeekInYear(DateTime date, int year, int firstWeekday) {
    const requiredDaysInYear = 4;
    final startWeekDate = firstDayOfWeek(date, firstWeekday: firstWeekday);
    final endWeekDate = lastDayOfWeek(date, firstWeekday: firstWeekday);

    if (startWeekDate.year == year && endWeekDate.year == year) {
      return true;
    } else if (endWeekDate.year == year) {
      final startYearDate = DateTime(year, DateTime.january, 1);
      final daysInPrevYear = getDaysDifference(startYearDate, startWeekDate);
      return daysInPrevYear < requiredDaysInYear;
    } else if (startWeekDate.year == year) {
      final startNextYearDate = DateTime(year + 1, DateTime.january, 1);
      final daysInNextYear = getDaysDifference(endWeekDate, startNextYearDate) + 1;
      return daysInNextYear < requiredDaysInYear;
    } else {
      return false;
    }
  }

  DateTime _date(bool utc, int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0, int microsecond = 0]) =>
      utc
          ? DateTime.utc(year, month, day, hour, minute, second, millisecond, microsecond)
          : DateTime(year, month, day, hour, minute, second, millisecond, microsecond);
}
