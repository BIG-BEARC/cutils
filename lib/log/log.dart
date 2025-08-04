// Package imports:

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// * @Author: chuxiong
/// * @Created at: 2022/5/18 2:47 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志工具类

final logger = LoggerUtils();

class LoggerUtils {
  LoggerUtils._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
    );
  }

  factory LoggerUtils() => _instance;

  static final LoggerUtils _instance = LoggerUtils._internal();
  late Logger _logger;

  /// Log a message at level [Level.trace].
  void t(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String tag = "",
  }) {
    if (kReleaseMode) {
      return;
    }
    if (tag.isNotEmpty) {
      _logger.t("$tag: $message", time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.t(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a message at level [Level.debug].
  void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String tag = "",
  }) {
    if (kReleaseMode) {
      return;
    }
    if (tag.isNotEmpty) {
      _logger.d("$tag: $message", time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.d(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a message at level [Level.info].
  void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String tag = "",
  }) {
    if (kReleaseMode) {
      return;
    }
    if (tag.isNotEmpty) {
      _logger.i("$tag: $message", time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.i(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a message at level [Level.warning].
  void w(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String tag = "",
  }) {
    if (kReleaseMode) {
      return;
    }
    if (tag.isNotEmpty) {
      _logger.w("$tag: $message", time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.w(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a message at level [Level.error].
  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String tag = "",
  }) {
    if (kReleaseMode) {
      return;
    }
    if (tag.isNotEmpty) {
      _logger.e("$tag: $message", time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.e(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a message at level [Level.fatal].
  void f(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String tag = "",
  }) {
    if (kReleaseMode) {
      return;
    }
    if (tag.isNotEmpty) {
      _logger.f("$tag: $message", time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.f(message, time: time, error: error, stackTrace: stackTrace);
    }
  }
}
