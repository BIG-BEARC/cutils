// Package imports:

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// * @Author: chuxiong
/// * @Created at: 2022/5/18 2:47 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description 日志工具类

/// 全局 [LoggerUtils] 单例，直接 `logger.i(...)` / `logger.e(...)` 使用。
///
/// 所有方法在 release 模式（[kReleaseMode]）下均为 no-op，避免线上输出。
final logger = LoggerUtils();

/// 对 `package:logger` 的薄封装：提供 `t/d/i/w/e/f` 六个级别方法，均带可选
/// [tag] 参数（输出形如 `"tag: message"`），并在 release 模式下静默。
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
      _logger.t("$tag: $message",
          time: time, error: error, stackTrace: stackTrace);
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
      _logger.d("$tag: $message",
          time: time, error: error, stackTrace: stackTrace);
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
      _logger.i("$tag: $message",
          time: time, error: error, stackTrace: stackTrace);
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
      _logger.w("$tag: $message",
          time: time, error: error, stackTrace: stackTrace);
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
      _logger.e("$tag: $message",
          time: time, error: error, stackTrace: stackTrace);
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
      _logger.f("$tag: $message",
          time: time, error: error, stackTrace: stackTrace);
    } else {
      _logger.f(message, time: time, error: error, stackTrace: stackTrace);
    }
  }
}
